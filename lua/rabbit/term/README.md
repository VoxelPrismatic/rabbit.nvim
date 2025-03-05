<h1>Rabbit Terminal API</h1>
Various APIs for creating UIs for user input
<ul>
    <li>
        <details>
            <summary><h2>Context API</h2></summary>
            Creates and manages various windows and their associated buffers. This allows for all windows to be closed at once
            when Rabbit is no longer focused, and allows child windows to be closed when the parent window is closed, too.
            <pre lang="lua">local CTX = require("rabbit.term.ctx")</pre>
            <ul>
                <li>
                    <details>
                        <summary>
                            <code>CTX.<b>append</b>(<i>bufnr</i>, <i>winnr</i>, <i>parent</i>)</code>
                            → <a href="../docs/ui.lua#L13">Rabbit.UI.Workspace</a>
                            <br>
                            Appends a buffer and window to the context. Also binds the <code>WinClosed</code> and <code>BufDelete</code> events.
                        </summary>
                        <ul>
                            <li>
                                <b>Parameters</b><br>
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
                            </li>
                            <li>
                                <b>Returns</b>
                                <table>
                                    <tr>
                                        <td><a href="../docs/ui.lua#L13">Rabbit.UI.Workspace</a></td>
                                        <td>The newly created workspace</td>
                                    </tr>
                                </table>
                            </li>
                        </ul>
                        <br><br>
                    </details>
                </li>
                <li>
                    <details>
                        <summary>
                            <code>CTX.<b>workspace</b>(<i>bufnr</i>, <i>winnr</i>)</code>
                            → <a href="../docs/ui.lua#L13">Rabbit.UI.Workspace</a>
                            <br>
                            Creates a workspace but does not append it to the context.
                        </summary>
                        <ul>
                            <li>
                                <b>Parameters</b><br>
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
                            </li>
                            <li>
                                <b>Returns</b>
                                <table>
                                    <tr>
                                        <td><a href="../docs/ui.lua#L13">Rabbit.UI.Workspace</a></td>
                                        <td>The newly created workspace</td>
                                    </tr>
                                </table>
                            </li>
                        </ul>
                        <br><br>
                    </details>
                </li>
                <li>
                    <details>
                        <summary>
                            <code>CTX.<b>clear</b>()</code>
                            <br>
                            Clears the context; closes all windows and buffers
                        </summary>
                        <ul>
                            <li><i>Takes no parameters</i></li>
                            <li><i>Doesn't return anything</i></li>
                        </ul>
                        <br><br>
                    </details>
                </li>
                <li>
                    <details>
                        <summary>
                            <code>CTX.<b>close</b>(<i>ws</i>)</code>
                            <br>
                            Closes a window and buffer, and removes it from the context stack
                        </summary>
                        <ul>
                            <li>
                                <b>Parameters</b>
                                <table>
                                    <tr>
                                        <th>param</th>
                                        <th>type</th>
                                        <th>details</th>
                                    </tr>
                                    <tr>
                                        <td>ws</td>
                                        <td><a href="../docs/ui.lua#L13">Rabbit.UI.Workspace</a></td>
                                        <td>Workspace to close</td>
                                    </tr>
                                </table>
                            </li>
                            <li><i>Doesn't return anything</i></li>
                        </ul>
                        <br><br>
                    </details>
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
                    <details>
                        <summary>
                            <code>UIL.<b>rect</b>(<i>win</i>, <i>z</i>)</code>
                            → <a href="https://neovim.io/doc/user/api.html#api-win_config">vim.api.keyset.win_config</a>
                            <br>
                            Creates a win_config based on width, hight, position, and split options, as specified in the user's config.
                        </summary>
                        <ul>
                            <li>
                                <b>Parameters</b>
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
                            </li>
                            <li>
                                <b>Returns</b>
                                <table>
                                    <tr>
                                        <td><a href="https://neovim.io/doc/user/api.html#api-win_config">vim.api.keyset.win_config</a></td>
                                        <td>Window config to be passed to <code>vim.api.nvim_open_win</code></td>
                                    </tr>
                                </table>
                            </li>
                            <li>
                                <b>Error handling</b>
                                <ol>
                                    <li>
                                        If the user's <code>opts.spawn.mode</code> is NOT <code>split</code> or <code>float</code>,
                                        it will fall back to <code>fullscreen</code>
                                    </li>
                                    <li>
                                        When the user's <code>opts.spawn.mode</code> is <code>split</code>,
                                        if the split side is not valid, it will fall back to <code>right</code>
                                    </li>
                                    <li>
                                        When the user's <code>opts.spawn.mode</code> is <code>float</code>,
                                        if the float side is not valid, it will fall back to the top-left corner
                                    </li>
                                    <li>Default width is 64</li>
                                    <li>Default height is 24</li>
                                </ol>
                            </li>
                        </ul>
                        <br><br>
                    </details>
                </li>
                <li>
                    <details>
                        <summary>
                            <code>UIL.<b>spawn</b>(<i>plugin</i>)</code><br>
                            Spawns a new listing window
                        </summary>
                        <ul>
                            <li>
                                <b>Parameters</b>
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
                            </li>
                            <li><i>Doesn't return anything</i></li>
                        </ul>
                        <br><br>
                    </details>
                </li>
                <li>
                    <details>
                        <summary>
                            <code>UIL.<b>draw_border</b>(<i>ws</i>)</code><br>
                            Draws the border for a workspace
                        </summary>
                        <ul>
                            <li>
                                <b>Parameters</b>
                                <table>
                                    <tr>
                                        <th>param</th>
                                        <th>type</th>
                                        <th>details</th>
                                    </tr>
                                    <tr>
                                        <td>ws</td>
                                        <td><a href="../docs/ui.lua#L13">Rabbit.UI.Workspace</a></td>
                                        <td>Workspace to draw the border for</td>
                                    </tr>
                                </table>
                            </li>
                            <li><i>Doesn't return anything</i></li>
                        </ul>
                        <br><br>
                    </details>
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
                    <details>
                        <summary>
                            <code>RECT.<b>calc</b>(<i>rect</i>, <i>win</i>)</code>
                            → <a href="../docs/ui.lua#L1">Rabbit.UI.Rect</a>
                            <br>
                            Creates a rect and trims to fit inside the window
                        </summary>
                        <ul>
                            <li>
                                <b>Parameters</b>
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
                            </li>
                            <li>
                                <b>Returns</b>
                                <table>
                                    <tr>
                                        <td><a href="../docs/ui.lua#L1">Rabbit.UI.Rect</a></td>
                                        <td>Trimmed rect</td>
                                    </tr>
                                </table>
                            </li>
                        </ul>
                        <br><br>
                    </details>
                </li>
                <li>
                    <details>
                        <summary>
                            <code>RECT.<b>win</b>(<i>rect</i>)</code>
                            → <a href="https://neovim.io/doc/user/api.html#api-win_config">vim.api.keyset.win_config</a>
                            <br>
                            Generates the win_config to be passed to <code>vim.api.nvim_open_win</code>
                        </summary>
                        <ul>
                            <li>
                                <b>Parameters</b>
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
                            </li>
                            <li>
                                <b>Returns</b>
                                <table>
                                    <tr>
                                        <td><a href="https://neovim.io/doc/user/api.html#api-win_config">vim.api.keyset.win_config</a></td>
                                        <td>Window config to be passed to <code>vim.api.nvim_open_win</code></td>
                                    </tr>
                                </table>
                            </li>
                        </ul>
                        <br><br>
                    </details>
                </li>
            </ul>
        </details>
    </li>
    <li>
        <details>
            <summary><h2>Border API</h2></summary>
            Allows the user to create custom borders
            <pre lang="lua">local BOX = require("rabbit.term.border")</pre>
            <ul>
                <li>
                    <details>
                        <summary>
                            <code>BOX.<b>expand</b>(<i>border_str</i>)</code>
                            → <a href="../docs/border.lua#L1">Rabbit.Term.Border.Box</a>
                            <br>
                            Expands a border string (<code>╭╮╰╯─│┃</code>) to a full <a href="../docs/border.lua#L1">Rabbit.Term.Border.Box</a>
                        </summary>
                        <ul>
                            <li>
                                <b>Parameters</b>
                                <table>
                                    <tr>
                                        <th>param</th>
                                        <th>type</th>
                                        <th>details</th>
                                    </tr>
                                    <tr>
                                        <td>border_str</td>
                                        <td>string</td>
                                        <td>Border string<br>[top left, top right, bottom left, bottom right, horizontal, vertical, scrollbar]</td>
                                    </tr>
                                </table>
                            </li>
                            <li>
                                <b>Returns</b>
                                <table>
                                    <tr>
                                        <td><a href="../docs/border.lua#L1">Rabbit.Term.Border.Box</a></td>
                                        <td>Border object</td>
                                    </tr>
                                </table>
                            </li>
                            <li>
                                <b>Error Handling</b>
                                <ol>
                                    <li>Everything is cast to a string</li>
                                    <li>If the string is too short, the associated part is an empty string</li>
                                </ol>
                            </li>
                        </ul>
                        <br><br>
                    </details>
                </li>
                <li>
                    <details>
                        <summary>
                            <code>BOX.<b>flag</b>(<i>kwargs</i>)</code>
                            → string
                            <br>
                            Creates a border string based on a few parameters
                        </summary>
                        <ul>
                            <li>
                                <b>Parameters</b>
                                <table>
                                    <tr>
                                        <th>param</th>
                                        <th>type</th>
                                        <th>details</th>
                                    </tr>
                                    <tr>
                                        <td>kwargs</td>
                                        <td><a href="../docs/border.lua#L37">Rabbit.Term.Border.Custom.Kwargs</a></td>
                                        <td>Table of border flags, including weight, corner style, and stroke style</td>
                                    </tr>
                                </table>
                            </li>
                            <li>
                                <b>Returns</b>
                                <table>
                                    <tr>
                                        <td>string</td>
                                        <td>Border string (<code>╭╮╰╯─│</code>)<br><i>*this does not include the scrollbar character</i></td>
                                    </tr>
                                </table>
                            </li>
                            <li>
                                <b>Throws</b>
                                <table>
                                    <tr>
                                        <td>Invalid border parameters</td>
                                        <td>If you somehow managed to bypass all the failsafes</td>
                                    </tr>
                                </table>
                            </li>
                            <li>
                                <b>Error Handling</b>
                                <ol>
                                    <li>If the weight is NOT <code>bold</code> or <code>double</code>, it will fall back to <code>thin</code></li>
                                    <li>If the weight is NOT <code>thin</code>, the corner style will be set to <code>square</code></li>
                                    <li>If the weight is <code>double</code>, the stroke style will be set to <code>double</code></li>
                                    <li>If the stroke style is not <code>dash</code>, <code>dot</code>, or <code>double</code>, it will fall back to <code>sold</code></li>
                                    <li>If the corner is NOT <code>round</code>, it will fall back to <code>square</code></li>
                                    <li>If you somehow passed these checks, it will throw an error (above)</li>
                                </ol>
                            </li>
                            <li>
                                <b>Note</b><br>
                                It is recommended to use <code>BOX.custom</code> instead of this function because it also accepts
                                <a href="../docs/border.lua#L43">Rabbit.Term.Border.Custom.Positional</a> (this is the helper function)
                            </li>
                        </ul>
                        <br><br>
                    </details>
                </li>
                <li>
                    <details>
                        <summary>
                            <code>BOX.<b>custom</b>(<i>kwargs</i>)</code>
                            → <a href="../docs/border.lua#L1">Rabbit.Term.Border.Box</a>
                            <br>
                            Creates a custom border, but also parses the scrollbar kwargs
                        </summary>
                        <ul>
                            <li>
                                <b>Parameters</b>
                                <table>
                                    <tr>
                                        <th>param</th>
                                        <th>type</th>
                                        <th>details</th>
                                    </tr>
                                    <tr>
                                        <td rowspan="2">kwargs</td>
                                        <td><a href="../docs/border.lua#L37">Rabbit.Term.Border.Custom.Kwargs</a></td>
                                        <td>Table of border flags, including weight, corner style, and stroke style</td>
                                    </tr>
                                    <tr>
                                        <td><a href="../docs/border.lua#L43">Rabbit.Term.Border.Custom.Positional</a></td>
                                        <td>
                                            Like the Kwargs, but you don't need the keys.<br>
                                            [ corner, weight, stroke, [ scrollbar weight, scrollbar stroke ] ]
                                        </td>
                                    </tr>
                                </table>
                            </li>
                            <li>
                                <b>Returns</b>
                                <table>
                                    <tr>
                                        <td><a href="../docs/border.lua#L1">Rabbit.Term.Border.Box</a></td>
                                        <td>Border object</td>
                                    </tr>
                                </table>
                            </li>
                            <li>
                                <b>Error Handling</b>
                                <ol>
                                    <li>If any field is nil, it will be reset to the default</li>
                                </ol>
                            </li>
                        </ul>
                        <br><br>
                    </details>
                </li>
                <li>
                    <details>
                        <summary>
                            <code>BOX.<b>normalize</b>(<i>border</i>)</code>
                            → <a href="../docs/border.lua#L1">Rabbit.Term.Border.Box</a>
                            <br>
                            Normalizes a border object. Accepts all types of borders
                        </summary>
                        <ul>
                            <li>
                                <b>Parameters</b>
                                <table>
                                    <tr>
                                        <th>param</th>
                                        <th>type</th>
                                        <th>details</th>
                                    </tr>
                                    <tr>
                                        <td rowspan="4">border</td>
                                        <td><a href="../docs/border.lua#L1">Rabbit.Term.Border.Box</a></td>
                                        <td>Border object. This is returned unchanged</td>
                                    </tr>
                                    <tr>
                                        <td>string</td>
                                        <td>Border string (<code>╭╮╰╯─│</code>). This is passed to <code>BOX.expand</code></td>
                                    </tr>
                                    <tr>
                                        <td><a href="../docs/border.lua#L37">Rabbit.Term.Border.Custom.Kwargs</a></td>
                                        <td>Table of border flags. This is passed to <code>BOX.custom</code></td>
                                    </tr>
                                    <tr>
                                        <td><a href="../docs/border.lua#L43">Rabbit.Term.Border.Custom.Positional</a></td>
                                        <td>
                                            Like the Kwargs, but you don't need the keys. This is passed to <code>BOX.custom</code>
                                        </td>
                                    </tr>
                                </table>
                            </li>
                            <li>
                                <b>Returns</b>
                                <table>
                                    <tr>
                                        <td><a href="../docs/border.lua#L1">Rabbit.Term.Border.Box</a></td>
                                        <td>Border object</td>
                                    </tr>
                                </table>
                            </li>
                            <li>
                                <b>Throws</b>
                                <table>
                                    <tr>
                                        <td>Expected string or table, got [...]</td>
                                        <td>The provided <code>border</code> is not a valid border object</td>
                                    </tr>
                                </table>
                            </li>
                        </ul>
                        <br><br>
                    </details>
                </li>
            </ul>
        </details>
    </li>

</ul>
