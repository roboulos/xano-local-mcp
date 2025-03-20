# Xano MCP Server using MCP SDK

This implementation uses the official MCP SDK to connect Claude with Xano databases. This approach correctly follows the Model Context Protocol standards, enabling Claude to seamlessly interact with your Xano data.

## Why a New Implementation?

The original HTTP-based implementation encountered several issues:

1. **Incompatible Communication Protocol**: The MCP protocol uses stdio (standard input/output) for communication, not HTTP. Our HTTP server implementation was fundamentally incompatible with how Claude expects to communicate with MCP servers.

2. **JSON-RPC Format**: MCP requires messages to follow a specific JSON-RPC format that our original implementation didn't support.

3. **Environment Issues**: The original implementation had challenges with dependency management and environment setup.

4. **Endpoint Format Mismatch**: We encountered challenges with the correct Xano API endpoint formats.

This new implementation addresses all these issues by using the official MCP SDK, which properly implements the protocol requirements.

## Setup Instructions

Follow these steps to set up and run the new MCP server:

1. **Run the setup script**:
   ```bash
   chmod +x setup_mcp_sdk.sh
   ./setup_mcp_sdk.sh
   ```

   This will:
   - Create a Python virtual environment
   - Install the required dependencies (`mcp[cli]` and `httpx`)
   - Make the server script executable

2. **Verify the setup**:
   After setup, you can manually test the server by running:
   ```bash
   source .venv/bin/activate
   ./xano_mcp_sdk.py --token "YOUR_XANO_API_TOKEN"
   ```

   The server should start and wait for input. Note that it won't display anything immediately as it's expecting JSON-RPC messages on stdin, which is how Claude will communicate with it.

3. **Configure Claude**:
   Update Claude's configuration by copying the contents of `claude_config_sdk.json` to `~/Library/Application Support/Claude/claude_desktop_config.json`.

   You can do this with the following command:
   ```bash
   cp /Users/sboulos/Desktop/xano-mcp-server/claude_config_sdk.json ~/Library/Application\ Support/Claude/claude_desktop_config.json
   ```

4. **Restart Claude**:
   Restart the Claude application for the changes to take effect.

## Features

This MCP server implementation includes the following tools:

1. **xano_list_instances**:
   - Lists all Xano instances associated with your account

2. **xano_get_instance_details**:
   - Gets detailed information about a specific Xano instance

3. **xano_list_databases**:
   - Lists all databases in a specific Xano instance

4. **xano_list_tables**:
   - Lists all tables in a specific Xano database

## Understanding the Implementation

This implementation is fundamentally different from the original in several key ways:

1. **MCP SDK**: It uses the official MCP SDK (`mcp.server.fastmcp.FastMCP`) which handles all the protocol details correctly.

2. **Async Implementation**: It uses asynchronous functions with `async/await` for better performance.

3. **Stdio Transport**: It uses the stdio transport (`mcp.run(transport='stdio')`) which is how Claude expects to communicate with MCP servers.

4. **Tool Decorators**: It registers tools using the `@mcp.tool()` decorator, which automatically handles parameter validation and response formatting.

5. **Error Logging**: It logs errors and debug information to stderr, which will appear in Claude's MCP logs for troubleshooting.

## Extending the Server

To add more tools to the server, simply add more functions with the `@mcp.tool()` decorator. For example, to add a tool to get table schema:

```python
@mcp.tool()
async def xano_get_table_schema(instance_name: str, database_name: str, table_name: str) -> Dict[str, Any]:
    """Get the schema for a specific Xano table.
    
    Args:
        instance_name: The name of the Xano instance
        database_name: The name of the Xano database
        table_name: The name of the table
    """
    token = get_token()
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
        "Accept": "application/json"
    }
    
    async with httpx.AsyncClient() as client:
        try:
            url = f"{XANO_API_BASE}/instance/{instance_name}/database/{database_name}/table/{table_name}/schema"
            response = await client.get(url, headers=headers)
            
            if response.status_code == 200:
                return {"schema": response.json()}
            else:
                return {"error": f"Failed to get table schema: {response.status_code}"}
        except Exception as e:
            return {"error": f"Error getting table schema: {str(e)}"}
```

This approach makes it easy to add new functionality while ensuring compatibility with the MCP protocol.

## Troubleshooting

If you encounter issues with the server, check the Claude MCP logs by:

1. Opening the Developer Tools in Claude (Ctrl+Shift+I or Cmd+Option+I)
2. Looking for logs with the "[xano]" prefix

These logs will contain any error messages or debug information printed to stderr by the server.

Common issues and solutions:

1. **"spawn uv ENOENT"**: This means Claude can't find the uv executable. Make sure uv is installed and added to your PATH.

2. **Module not found errors**: Make sure all dependencies are installed in the virtual environment:
   ```bash
   source .venv/bin/activate
   uv add "mcp[cli]" httpx
   ```

3. **Authentication errors**: Verify your Xano API token is valid and has the necessary permissions.

4. **Endpoint not found**: Verify the endpoint paths match the Xano API documentation.
