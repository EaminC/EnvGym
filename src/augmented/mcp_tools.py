from dataclasses import dataclass
import os
import shlex
from typing import Self

from dotenv import load_dotenv

load_dotenv()


@dataclass
class McpToolInfo:
    name: str
    shell_cmd_pattern: str
    main_cmd_options: str = ""
    mcp_params: str = ""

    @property
    def shell_cmd(self) -> str:
        return self.shell_cmd_pattern.format(
            main_cmd_options=self.main_cmd_options,
            mcp_params=self.mcp_params,
        )

    def append_mcp_params(self, params: str) -> Self:
        if params:
            self.mcp_params += params
        return self

    def append_main_cmd_options(self, options: str) -> Self:
        if options:
            self.main_cmd_options += options
        return self

    def to_common_params(self) -> dict[str, str]:
        command, *args = shlex.split(self.shell_cmd)
        return dict(
            name=self.name,
            command=command,
            args=args,
        )


class McpCmdOptions:
    uvx_use_cn_mirror = (
        ("--extra-index-url https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple")
        if os.environ.get("USE_CN_MIRROR")
        else ""
    )
    npx_use_cn_mirror = (
        ("--registry https://registry.npmmirror.com")
        if os.environ.get("USE_CN_MIRROR")
        else ""
    )
    fetch_server_mcp_use_proxy = (
        f"--proxy-url {os.environ.get('PROXY_URL')}"
        if os.environ.get("PROXY_URL")
        else ""
    )


class PresetMcpTools:
    filesystem = McpToolInfo(
        name="filesystem",
        shell_cmd_pattern="npx {main_cmd_options} -y @modelcontextprotocol/server-filesystem {mcp_params}",
    ).append_main_cmd_options(
        McpCmdOptions.npx_use_cn_mirror,
    )
    fetch = (
        McpToolInfo(
            name="fetch",
            shell_cmd_pattern="uvx {main_cmd_options} mcp-server-fetch {mcp_params}",
        )
        .append_main_cmd_options(
            McpCmdOptions.uvx_use_cn_mirror,
        )
        .append_mcp_params(
            McpCmdOptions.fetch_server_mcp_use_proxy,
        )
    )
