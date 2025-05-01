import asyncio
import os
from mcp import Tool
from openai import NOT_GIVEN, AsyncOpenAI
from dataclasses import dataclass, field

from openai.types import FunctionDefinition
from openai.types.chat import (
    ChatCompletionMessageParam,
    ChatCompletionToolParam,
)
import dotenv
from pydantic import BaseModel
from rich import print as rprint

from augmented.utils import pretty
from augmented.utils.info import DEFAULT_MODEL_NAME

PRETTY_LOGGER = pretty.ALogger("[ChatOpenAI]")

dotenv.load_dotenv()


class ToolCallFunction(BaseModel):
    name: str = ""
    arguments: str = ""


class ToolCall(BaseModel):
    id: str = ""
    function: ToolCallFunction = ToolCallFunction()


class ChatOpenAIChatResponse(BaseModel):
    content: str = ""
    tool_calls: list[ToolCall] = []


@dataclass
class AsyncChatOpenAI:
    model: str
    messages: list[ChatCompletionMessageParam] = field(default_factory=list)
    tools: list[Tool] = field(default_factory=list)

    system_prompt: str = ""
    context: str = ""

    llm: AsyncOpenAI = field(init=False)

    def __post_init__(self) -> None:
        self.llm = AsyncOpenAI(
            api_key=os.environ.get("OPENAI_API_KEY"),
            base_url=os.environ.get("OPENAI_BASE_URL"),
        )
        if self.system_prompt:
            self.messages.insert(0, {"role": "system", "content": self.system_prompt})
        if self.context:
            self.messages.append({"role": "user", "content": self.context})

    async def chat(
        self, prompt: str = "", print_llm_output: bool = True
    ) -> ChatOpenAIChatResponse:
        try:
            return await self._chat(prompt, print_llm_output)
        except Exception as e:
            rprint(f"Error during chat: {e!s}")
            raise

    async def _chat(
        self, prompt: str = "", print_llm_output: bool = True
    ) -> ChatOpenAIChatResponse:
        PRETTY_LOGGER.title("CHAT")
        if prompt:
            self.messages.append({"role": "user", "content": prompt})

        content = ""
        tool_calls: list[ToolCall] = []
        printed_llm_output = False
        param_tools = self.get_tools_definition() or NOT_GIVEN
        async with await self.llm.chat.completions.create(
            model=self.model,
            messages=self.messages,
            tools=param_tools,
            stream=True,
        ) as stream:
            PRETTY_LOGGER.title("RESPONSE")
            async for chunk in stream:
                delta = chunk.choices[0].delta
                # 处理 content
                if delta.content:
                    content += delta.content or ""
                    if print_llm_output:
                        print(delta.content, end="")
                        printed_llm_output = True
                # 处理 tool_calls
                if delta.tool_calls:
                    for tool_call in delta.tool_calls:
                        if len(tool_calls) <= tool_call.index:
                            tool_calls.append(ToolCall())
                        this_tool_call = tool_calls[tool_call.index]
                        if tool_call.id:
                            this_tool_call.id += tool_call.id or ""
                        if tool_call.function:
                            if tool_call.function.name:
                                this_tool_call.function.name += (
                                    tool_call.function.name or ""
                                )
                            if tool_call.function.arguments:
                                this_tool_call.function.arguments += (
                                    tool_call.function.arguments or ""
                                )
        if printed_llm_output:
            print()
        self.messages.append(
            {
                "role": "assistant",
                "content": content,
                "tool_calls": [
                    {
                        "type": "function",
                        "id": tc.id,
                        "function": {
                            "name": tc.function.name,
                            "arguments": tc.function.arguments,
                        },
                    }
                    for tc in tool_calls
                ],
            }
        )
        return ChatOpenAIChatResponse(
            content=content,
            tool_calls=tool_calls,
        )

    def get_tools_definition(self) -> list[ChatCompletionToolParam]:
        return [
            ChatCompletionToolParam(
                type="function",
                function=FunctionDefinition(
                    name=t.name,
                    description=t.description,
                    parameters=t.inputSchema,
                ),
            )
            for t in self.tools
        ]

    def append_tool_result(self, tool_call_id: str, tool_output: str) -> None:
        self.messages.append(
            {
                "role": "tool",
                "tool_call_id": tool_call_id,
                "content": tool_output,
            }
        )


async def example() -> None:
    llm = AsyncChatOpenAI(
        model=DEFAULT_MODEL_NAME,
    )
    chat_resp = await llm.chat(prompt="Hello")
    rprint(chat_resp)


if __name__ == "__main__":
    asyncio.run(example())
