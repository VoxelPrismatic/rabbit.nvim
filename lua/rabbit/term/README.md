<details>
    <summary><h1>Rabbit Terminal API</h1></summary>
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
                            Appends a buffer and window to the context
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
                                                <td>? parent</td>
                                                <td>Rabbit.UI.Workspace</td>
                                                <td>Parent workspace; When the parent is deleted, this workspace will be deleted too</td>
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
</details>
