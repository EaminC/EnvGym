import asyncio
from dataclasses import dataclass
import json

from rich import print as rprint

from augmented.chat_openai import AsyncChatOpenAI
from augmented.mcp_client import MCPClient
from augmented.mcp_tools import PresetMcpTools
from augmented.utils import pretty
from augmented.utils.info import DEFAULT_MODEL_NAME, PROJECT_ROOT_DIR

PRETTY_LOGGER = pretty.ALogger("[Agent]")


@dataclass
class Agent:
    mcp_clients: list[MCPClient]
    model: str
    llm: AsyncChatOpenAI | None = None
    system_prompt: str = ""
    context: str = ""

    async def init(self) -> None:
        PRETTY_LOGGER.title("INIT LLM&TOOLS")
        tools = []
        for mcp_client in self.mcp_clients:
            await mcp_client.init()
            tools.extend(mcp_client.get_tools())
        self.llm = AsyncChatOpenAI(
            self.model,
            tools=tools,
            system_prompt=self.system_prompt,
            context=self.context,
        )

    async def cleanup(self) -> None:
        PRETTY_LOGGER.title("CLEANUP LLM&TOOLS")

        while self.mcp_clients:
            # NOTE: 需要先处理其他依赖于mcp_client的资源, 不然会有一堆错误, 如
            # RuntimeError: Attempted to exit cancel scope in a different task than it was entered in
            # RuntimeError: Attempted to exit a cancel scope that isn't the current tasks's current cancel scope an error occurred during closing of asynchronous generator <async_generator object stdio_client at 0x76c3e08ee0c0>
            mcp_client = self.mcp_clients.pop()
            await mcp_client.cleanup()

    async def invoke(self, prompt: str) -> str | None:
        return await self._invoke(prompt)

    async def _invoke(self, prompt: str) -> str | None:
        if self.llm is None:
            raise ValueError("llm not call .init()")
        chat_resp = await self.llm.chat(prompt)
        i = 0
        while True:
            PRETTY_LOGGER.title(f"INVOKE CYCLE {i}")
            i += 1
            # 处理工具调用
            rprint(chat_resp)
            if chat_resp.tool_calls:
                for tool_call in chat_resp.tool_calls:
                    target_mcp_client: MCPClient | None = None
                    for mcp_client in self.mcp_clients:
                        if tool_call.function.name in [
                            t.name for t in mcp_client.get_tools()
                        ]:
                            target_mcp_client = mcp_client
                            break
                    if target_mcp_client:
                        PRETTY_LOGGER.title(f"TOOL USE `{tool_call.function.name}`")
                        rprint("with args:", tool_call.function.arguments)
                        mcp_result = await target_mcp_client.call_tool(
                            tool_call.function.name,
                            json.loads(tool_call.function.arguments),
                        )
                        rprint("call result:", mcp_result)
                        self.llm.append_tool_result(
                            tool_call.id, mcp_result.model_dump_json()
                        )
                    else:
                        self.llm.append_tool_result(tool_call.id, "tool not found")
                chat_resp = await self.llm.chat()
            else:
                return chat_resp.content


async def example() -> None:
    enabled_mcp_clients = []
    agent = None
    try:
        for mcp_tool in [
            PresetMcpTools.filesystem.append_mcp_params(f" {PROJECT_ROOT_DIR!s}"),
            PresetMcpTools.fetch,
        ]:
            rprint(mcp_tool.shell_cmd)
            mcp_client = MCPClient(**mcp_tool.to_common_params())
            enabled_mcp_clients.append(mcp_client)

        agent = Agent(
            model=DEFAULT_MODEL_NAME,
            mcp_clients=enabled_mcp_clients,
        )
        await agent.init()

        resp = await agent.invoke(
            f"爬取 https://news.ycombinator.com 的内容, 并且总结后保存在 {PROJECT_ROOT_DIR / 'output' / 'step3-agent-with-mcp'!s} 目录下的news.md文件中"
        )
        rprint(resp)
    except Exception as e:
        rprint(f"Error during agent execution: {e!s}")
        raise
    finally:
        if agent:
            await agent.cleanup()


if __name__ == "__main__":
    asyncio.run(example())
