from typing import AsyncIterable, Optional, Any, AsyncGenerator
from dataclasses import dataclass
import json
from openai import OpenAI
from agent_squad.agents import (
    Agent,
    AgentOptions,
    AgentStreamResponse
)
from agent_squad.types import (
    ConversationMessage,
    ParticipantRole,
    OPENAI_MODEL_ID_GPT_O_MINI,
    TemplateVariables,
    AgentProviderType,
)
from agent_squad.utils import Logger, AgentTools, AgentTool
from agent_squad.retrievers import Retriever


@dataclass
class HybridAgentOptions(AgentOptions):
    """
    混合Agent的配置选项，支持OpenAI API和tools功能
    """
    api_key: str = None
    model: Optional[str] = None
    streaming: Optional[bool] = None
    inference_config: Optional[dict[str, Any]] = None
    custom_system_prompt: Optional[dict[str, Any]] = None
    retriever: Optional[Retriever] = None
    client: Optional[Any] = None
    tool_config: dict[str, Any] | AgentTools | None = None


class HybridAgent(Agent):
    """
    混合型Agent，结合了OpenAI API的调用能力和Bedrock Agent的tool处理能力
    """
    
    def __init__(self, options: HybridAgentOptions):
        super().__init__(options)
        
        if not options.api_key:
            raise ValueError("OpenAI API key is required")

        # 初始化OpenAI客户端
        if options.client:
            self.client = options.client
        else:
            self.client = OpenAI(api_key=options.api_key)

        self.model = options.model or OPENAI_MODEL_ID_GPT_O_MINI
        self.streaming = options.streaming or False
        self.retriever: Optional[Retriever] = options.retriever
        self.tool_config: Optional[dict[str, Any]] = options.tool_config

        # 默认推理配置
        default_inference_config = {
            'maxTokens': 1000,
            'temperature': 0.7,
            'topP': 0.9,
            'stopSequences': None
        }

        if options.inference_config:
            self.inference_config = {**default_inference_config, **options.inference_config}
        else:
            self.inference_config = default_inference_config

        # 系统提示模板
        self.prompt_template = f"""You are a {self.name}.
        {self.description}
        You will engage in an open-ended conversation, providing helpful and accurate information based on your expertise.
        When using tools, make sure to properly format your tool calls and handle the responses appropriately.
        The conversation will proceed as follows:
        - The human may ask an initial question or provide a prompt on any topic.
        - You will provide a relevant and informative response.
        - If tools are available and relevant to the request, use them to provide more accurate information.
        - The human may then follow up with additional questions or prompts.
        Throughout the conversation, you should aim to:
        - Understand the context and intent behind each question or prompt.
        - Use available tools when they can provide better or more accurate information.
        - Provide substantive and well-reasoned responses that directly address the query.
        - Ask for clarification if any part of the question or prompt is ambiguous.
        - Maintain a consistent, respectful, and engaging tone."""

        self.system_prompt = ""
        self.custom_variables: TemplateVariables = {}
        self.default_max_recursions = 20

        if options.custom_system_prompt:
            self.set_system_prompt(
                options.custom_system_prompt.get('template'),
                options.custom_system_prompt.get('variables')
            )

    def is_streaming_enabled(self) -> bool:
        return self.streaming is True

    async def _prepare_system_prompt(self, input_text: str) -> str:
        """准备系统提示，包含可选的检索上下文"""
        self.update_system_prompt()
        system_prompt = self.system_prompt

        if self.retriever:
            response = await self.retriever.retrieve_and_combine_results(input_text)
            system_prompt += f"\nHere is the context to use to answer the user's question:\n{response}"

        return system_prompt

    def _prepare_tools_for_openai(self) -> list[dict]:
        """准备OpenAI格式的tools"""
        if not self.tool_config:
            return []
        
        tools = []
        if isinstance(self.tool_config["tool"], AgentTools):
            # 如果是AgentTools对象，转换为OpenAI格式
            for tool in self.tool_config["tool"].tools:
                tools.append(tool.to_openai_format())
        elif isinstance(self.tool_config["tool"], list):
            # 如果是tool列表
            for tool in self.tool_config["tool"]:
                if isinstance(tool, AgentTool):
                    tools.append(tool.to_openai_format())
                else:
                    tools.append(tool)
        else:
            # 单个tool
            if isinstance(self.tool_config["tool"], AgentTool):
                tools.append(self.tool_config["tool"].to_openai_format())
            else:
                tools.append(self.tool_config["tool"])
        
        return tools

    def _get_max_recursions(self) -> int:
        """获取最大递归次数"""
        if not self.tool_config:
            return 1
        return self.tool_config.get("toolMaxRecursions", self.default_max_recursions)

    async def process_request(
        self,
        input_text: str,
        user_id: str,
        session_id: str,
        chat_history: list[ConversationMessage],
        additional_params: Optional[dict[str, str]] = None
    ) -> ConversationMessage | AsyncIterable[Any]:
        """
        处理对话请求，支持流式和单次响应模式
        """
        try:
            # 准备系统提示
            system_prompt = await self._prepare_system_prompt(input_text)

            # 准备消息历史
            messages = [
                {"role": "system", "content": system_prompt},
                *[{
                    "role": msg.role.lower(),
                    "content": msg.content[0].get('text', '') if msg.content else ''
                } for msg in chat_history],
                {"role": "user", "content": input_text}
            ]

            # 准备工具
            tools = self._prepare_tools_for_openai()

            # 准备请求选项
            request_options = {
                "model": self.model,
                "messages": messages,
                "max_tokens": self.inference_config.get('maxTokens'),
                "temperature": self.inference_config.get('temperature'),
                "top_p": self.inference_config.get('topP'),
                "stop": self.inference_config.get('stopSequences'),
                "stream": self.streaming
            }

            # 如果有工具，添加到请求选项
            if tools:
                request_options["tools"] = tools
                request_options["tool_choice"] = "auto"

            # 根据是否流式处理选择处理方式
            if self.streaming:
                return self._handle_streaming_with_tools(request_options, messages)
            else:
                return await self._handle_single_response_with_tools(request_options, messages)

        except Exception as error:
            Logger.error(f"Error in Hybrid Agent: {str(error)}")
            raise error

    async def _handle_single_response_with_tools(
        self, 
        request_options: dict[str, Any], 
        messages: list[dict]
    ) -> ConversationMessage:
        """处理单次响应，支持工具调用"""
        max_recursions = self._get_max_recursions()
        current_messages = messages.copy()
        
        while max_recursions > 0:
            # 更新消息
            request_options["messages"] = current_messages
            request_options["stream"] = False
            
            # 调用OpenAI API
            response = self.client.chat.completions.create(**request_options)
            
            if not response.choices:
                raise ValueError('No choices returned from OpenAI API')

            message = response.choices[0].message
            
            # 检查是否有工具调用
            if message.tool_calls:
                # 添加助手消息到对话历史
                current_messages.append({
                    "role": "assistant",
                    "content": message.content,
                    "tool_calls": [
                        {
                            "id": tool_call.id,
                            "type": tool_call.type,
                            "function": {
                                "name": tool_call.function.name,
                                "arguments": tool_call.function.arguments
                            }
                        } for tool_call in message.tool_calls
                    ]
                })
                
                # 处理工具调用
                for tool_call in message.tool_calls:
                    tool_result = await self._execute_tool_call(tool_call)
                    
                    # 添加工具结果到对话历史
                    current_messages.append({
                        "role": "tool",
                        "content": tool_result,
                        "tool_call_id": tool_call.id
                    })
                
                max_recursions -= 1
                continue
            else:
                # 没有工具调用，返回最终响应
                return ConversationMessage(
                    role=ParticipantRole.ASSISTANT.value,
                    content=[{"text": message.content or ""}]
                )
        
        # 达到最大递归次数
        return ConversationMessage(
            role=ParticipantRole.ASSISTANT.value,
            content=[{"text": "Maximum tool recursions reached."}]
        )

    async def _handle_streaming_with_tools(
        self, 
        request_options: dict[str, Any], 
        messages: list[dict]
    ) -> AsyncGenerator[AgentStreamResponse, None]:
        """处理流式响应，支持工具调用"""
        max_recursions = self._get_max_recursions()
        current_messages = messages.copy()
        
        while max_recursions > 0:
            request_options["messages"] = current_messages
            
            # 调用OpenAI流式API
            stream = self.client.chat.completions.create(**request_options)
            
            accumulated_message = ""
            tool_calls = []
            current_tool_call = None
            
            try:
                for chunk in stream:
                    if chunk.choices and len(chunk.choices) > 0:
                        delta = chunk.choices[0].delta
                        
                        if delta.content:
                            content = delta.content
                            accumulated_message += content
                            yield AgentStreamResponse(text=content)
                        
                        # 处理工具调用
                        if delta.tool_calls:
                            for tool_call_delta in delta.tool_calls:
                                if tool_call_delta.index is not None:
                                    # 新的工具调用
                                    while tool_call_delta.index >= len(tool_calls):
                                        tool_calls.append({
                                            "id": "",
                                            "type": "function",
                                            "function": {"name": "", "arguments": ""}
                                        })
                                    current_tool_call = tool_calls[tool_call_delta.index]
                                
                                if tool_call_delta.id:
                                    current_tool_call["id"] = tool_call_delta.id
                                
                                if tool_call_delta.function:
                                    if tool_call_delta.function.name:
                                        current_tool_call["function"]["name"] = tool_call_delta.function.name
                                    if tool_call_delta.function.arguments:
                                        current_tool_call["function"]["arguments"] += tool_call_delta.function.arguments
            except Exception as e:
                Logger.error(f"Error processing streaming response: {str(e)}")
                yield AgentStreamResponse(text=f"Error in streaming: {str(e)}")
                return
            
            # 如果有工具调用，处理它们
            if tool_calls and any(call.get("function", {}).get("name") for call in tool_calls):
                # 添加助手消息
                current_messages.append({
                    "role": "assistant",
                    "content": accumulated_message,
                    "tool_calls": tool_calls
                })
                
                # 执行工具调用
                for tool_call in tool_calls:
                    if tool_call.get("function", {}).get("name"):
                        tool_result = await self._execute_tool_call_dict(tool_call)
                        current_messages.append({
                            "role": "tool",
                            "content": tool_result,
                            "tool_call_id": tool_call["id"]
                        })
                
                max_recursions -= 1
                continue
            else:
                # 没有工具调用，返回最终消息
                final_message = ConversationMessage(
                    role=ParticipantRole.ASSISTANT.value,
                    content=[{"text": accumulated_message}]
                )
                yield AgentStreamResponse(final_message=final_message)
                return
        
        # 达到最大递归次数
        final_message = ConversationMessage(
            role=ParticipantRole.ASSISTANT.value,
            content=[{"text": "Maximum tool recursions reached."}]
        )
        yield AgentStreamResponse(final_message=final_message)

    async def _execute_tool_call(self, tool_call) -> str:
        """执行工具调用（OpenAI格式）"""
        try:
            tool_name = tool_call.function.name
            arguments = json.loads(tool_call.function.arguments)
            
            if isinstance(self.tool_config["tool"], AgentTools):
                # 使用AgentTools执行
                tool = next(
                    (t for t in self.tool_config["tool"].tools if t.name == tool_name), 
                    None
                )
                if tool:
                    result = await tool.func(**arguments)
                    return str(result)
                else:
                    return f"Tool '{tool_name}' not found"
            else:
                return f"Tool execution not supported for this configuration"
        
        except Exception as e:
            return f"Error executing tool '{tool_call.function.name}': {str(e)}"

    async def _execute_tool_call_dict(self, tool_call_dict: dict) -> str:
        """执行工具调用（字典格式）"""
        try:
            tool_name = tool_call_dict["function"]["name"]
            arguments = json.loads(tool_call_dict["function"]["arguments"])
            
            if isinstance(self.tool_config["tool"], AgentTools):
                # 使用AgentTools执行
                tool = next(
                    (t for t in self.tool_config["tool"].tools if t.name == tool_name), 
                    None
                )
                if tool:
                    result = await tool.func(**arguments)
                    return str(result)
                else:
                    return f"Tool '{tool_name}' not found"
            else:
                return f"Tool execution not supported for this configuration"
        
        except Exception as e:
            return f"Error executing tool '{tool_name}': {str(e)}"

    def set_system_prompt(self,
                         template: Optional[str] = None,
                         variables: Optional[TemplateVariables] = None) -> None:
        """设置系统提示"""
        if template:
            self.prompt_template = template
        if variables:
            self.custom_variables = variables
        self.update_system_prompt()

    def update_system_prompt(self) -> None:
        """更新系统提示"""
        all_variables: TemplateVariables = {**self.custom_variables}
        self.system_prompt = self.replace_placeholders(self.prompt_template, all_variables)

    @staticmethod
    def replace_placeholders(template: str, variables: TemplateVariables) -> str:
        """替换模板中的占位符"""
        import re
        def replace(match):
            key = match.group(1)
            if key in variables:
                value = variables[key]
                return '\n'.join(value) if isinstance(value, list) else str(value)
            return match.group(0)

        return re.sub(r'{{(\w+)}}', replace, template) 