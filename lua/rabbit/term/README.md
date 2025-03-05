<h1>Rabbit Terminal API</h1>
Various APIs for creating UIs for user input
<ul>
    <li>
        <details>
            <summary><h2>Context API</h2></summary>
            Creates and manages various windows and their associated buffers
            <pre lang="lua">local CTX = require("rabbit.term.ctx")</pre>
            <ul>
                <li>
                    <code>CTX.<b>append</b>(<i>bufnr</i>, <i>winnr</i>, <i>parent</i>)</code>
                    Appends a buffer and window to the context. Also binds the <code>WinClosed</code> and <code>BufDelete</code> events.
                    <ul>
                        <li>
                            <details>
                                <summary>Parameters</summary>
                                <table>
                                    <tr>
                                        <th>param</th>
                                        <th>type</th>
                                        <th>details</th>
                                    </tr>
                                    <tr>
                                        <td>bufnr</td>
                                        <td>integer</td>
                                        <td>Buffer ID</td>
                                    </tr>
                                    <tr>
                                        <td>winnr</td>
                                        <td>integer</td>
                                        <td>Window ID</td>
                                    </tr>
                                    <tr>
                                        <td>parent</td>
                                        <td><a href="../docs/ui.lua#L13">Rabbit.UI.Workspace</a></td>
                                        <td>Parent workspace; When the parent is deleted, this workspace will be deleted too</td>
                                    </tr>
                                </table>
                            </details>
                        </li>
                        <li>
                            <details>
                                <summary>Returns</summary>
                                <table>
                                    <tr>
                                        <td><a href="../docs/ui.lua#L13">Rabbit.UI.Workspace</a></td>
                                        <td>The newly created workspace</td>
                                    </tr>
                                </table>
                            </details>
                        </li>
                    </ul>
                </li>
                <li>
                    <code>CTX.<b>workspace</b>(<i>bufnr</i>, <i>winnr</i>)</code>
                    Creates a workspace but does not append it to the context.
                    <ul>
                        <li>
                            <details>
                                <summary>Parameters</summary>
                                <table>
                                    <tr>
                                        <th>param</th>
                                        <th>type</th>
                                        <th>details</th>
                                    </tr>
                                    <tr>
                                        <td>bufnr</td>
                                        <td>integer</td>
                                        <td>Buffer ID</td>
                                    </tr>
                                    <tr>
                                        <td>winnr</td>
                                        <td>integer</td>
                                        <td>Window ID</td>
                                    </tr>
                                </table>
                            </details>
                        </li>
                        <li>
                            <details>
                                <summary>Returns</summary>
                                <table>
                                    <tr>
                                        <td><a href="../docs/ui.lua#L13">Rabbit.UI.Workspace</a></td>
                                        <td>The newly created workspace</td>
                                    </tr>
                                </table>
                            </details>
                        </li>
                    </ul>
                </li>
                <li>
                    <code>CTX.<b>clear</b>()</code>
                    Clears the context; closes all windows and buffers
                </li>
                <li>
                    <code>CTX.<b>close</b>(<i>bufnr</i>, <i>winnr</i>)</code>
                    Closes a window and buffer
                    <ul>
                        <li>
                            <details>
                                <summary>Parameters</summary>
                                <table>
                                    <tr>
                                        <th>param</th>
                                        <th>type</th>
                                        <th>details</th>
                                    </tr>
                                    <tr>
                                        <td>bufnr</td>
                                        <td>integer</td>
                                        <td>Buffer ID</td>
                                    </tr>
                                    <tr>
                                        <td>winnr</td>
                                        <td>integer</td>
                                        <td>Window ID</td>
                                    </tr>
                                </table>
                            </details>
                        </li>
                    </ul>
                </li>
                <li>
                    <code>CTX.<b>link</b>(<i>parent</i>, <i>child</i>)</code>
                    Links a child workspace to a parent workspace so when the parent is closed, the child is closed, too.
                    <ul>
                        <li>
                            <details>
                                <summary>Parameters</summary>
                                <table>
                                    <tr>
                                        <th>param</th>
                                        <th>type</th>
                                        <th>details</th>
                                    </tr>
                                    <tr>
                                        <td>parent</td>
                                        <td><a href="../docs/ui.lua#L13">Rabbit.UI.Workspace</a></td>
                                        <td>Parent workspace</td>
                                    </tr>
                                    <tr>
                                        <td>child</td>
                                        <td><a href="../docs/ui.lua#L13">Rabbit.UI.Workspace</a></td>
                                        <td>Child workspace</td>
                                    </tr>
                                </table>
                            </details>
                        </li>
                    </ul>
                </li>
            </ul>
        </details>
    </li>
    <li>
        <details>
            <summary><h2>Listing API</h2></summary>
            Lists the buffers, files, and collections to the workspace provided by the Context API
            <pre lang="lua">local UIL = require("rabbit.term.listing")</pre>
            <ul>
                <li>
                    <code>UIL.<b>rect</b>(<i>win</i>, <i>z</i>)</code>
                    Creates a win_config based on width, hight, position, and split options, as specified in the user's config.
                    <ul>
                        <li>
                            <details>
                                <summary>Parameters</summary>
                                <table>
                                    <tr>
                                        <th>param</th>
                                        <th>type</th>
                                        <th>details</th>
                                    </tr>
                                    <tr>
                                        <td>win</td>
                                        <td>integer</td>
                                        <td>Parent window. This is used to make sure Rabbit's workspaces aren't out of bounds.</td>
                                    </tr>
                                    <tr>
                                        <td>z</td>
                                        <td>integer</td>
                                        <td>Z-index</td>
                                    </tr>
                                </table>
                            </details>
                        </li>
                        <li>
                            <details>
                                <summary>Returns</summary>
                                <table>
                                    <tr>
                                        <td>vim.api.keyset.win_config</td>
                                        <td>Window config to be passed to <code>vim.api.nvim_open_win</code></td>
                                    </tr>
                                </table>
                            </details>
                        </li>
                        <li>
                            <details>
                                <summary>Error handling</summary>
                                <ol>
                                    <li>If the user's <code>opts.spawn.mode</code> is NOT "split" or "float", it will fall back to "fullscreen"</li>
                                    <li>When the user's <code>opts.spawn.mode</code> is "split", if the split side is not valid, it will fall back to "right"</li>
                                    <li>When the user's <code>opts.spawn.mode</code> is "float", if the float side is not valid, it will fall back to the top-left corner</li>
                                    <li>Default width is 64</li>
                                    <li>Default height is 24</li>
                                </ol>
                            </details>
                        </li>
                    </ul>
                </li>
                <li>
                    <code>UIL.<b>spawn</b>(<i>plugin</i>)</code>
                    Spawns a new listing window
                    <ul>
                        <li>
                            <details>
                                <summary>Parameters</summary>
                                <table>
                                    <tr>
                                        <th>param</th>
                                        <th>type</th>
                                        <th>details</th>
                                    </tr>
                                    <tr>
                                        <td>plugin</td>
                                        <td>string</td>
                                        <td>Plugin name to open a listing for</td>
                                    </tr>
                                </table>
                            </details>
                        </li>
                    </ul>
                </li>
            </ul>
        </details>
    </li>
    <li>
        <details>
            <summary><h2>Rect API</h2></summary>
            Bounding client rects
            <pre lang="lua">local RECT = require("rabbit.term.rect")</pre>
            <ul>
                <li>
                    <code>RECT.<b>calc</b>(<i>rect</i>, <i>win</i>)</code>
                    Creates a rect and trims to fit inside the window
                    <ul>
                        <li>
                            <details>
                                <summary>Parameters</summary>
                                <table>
                                    <tr>
                                        <th>param</th>
                                        <th>type</th>
                                        <th>details</th>
                                    </tr>
                                    <tr>
                                        <td>rect</td>
                                        <td><a href="../docs/ui.lua#L1">Rabbit.UI.Rect</a></td>
                                        <td>Initial bounding rect, with X, Y, width and height</td>
                                    </tr>
                                    <tr>
                                        <td>win</td>
                                        <td>integer</td>
                                        <td>Window ID to make sure the rect is in bounds. If not, it will be trimmed to fit.</td>
                                    </tr>
                                </table>
                            </details>
                        </li>
                        <li>
                            <details>
                                <summary>Returns</summary>
                                <table>
                                    <tr>
                                        <td><a href="../docs/ui.lua#L1">Rabbit.UI.Rect</a></td>
                                        <td>Trimmed rect</td>
                                    </tr>
                                </table>
                            </details>
                        </li>
                    </ul>
                </li>
                <li>
                    <code>RECT.<b>win</b>(<i>rect</i>)</code>
                    Generates the win_config to be passed to <code>vim.api.nvim_open_win</code>
                    <ul>
                        <li>
                            <details>
                                <summary>Parameters</summary>
                                <table>
                                    <tr>
                                        <th>param</th>
                                        <th>type</th>
                                        <th>details</th>
                                    </tr>
                                    <tr>
                                        <td>rect</td>
                                        <td><a href="../docs/ui.lua#L1">Rabbit.UI.Rect</a></td>
                                        <td>Final bounding rect, with X, Y, width, height, and z-index</td>
                                    </tr>
                                </table>
                            </details>
                        </li>
                        <li>
                            <details>
                                <summary>Returns</summary>
                                <table>
                                    <tr>
                                        <td>vim.api.keyset.win_config</td>
                                        <td>Window config to be passed to <code>vim.api.nvim_open_win</code></td>
                                    </tr>
                                </table>
                            </details>
                        </li>
                    </ul>
                </li>
            </ul>
        </details>
    </li>
</ul>
