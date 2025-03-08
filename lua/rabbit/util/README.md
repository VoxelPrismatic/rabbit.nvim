<h1>Rabbit Utilities API</h1>
Various APIs that are useful for various other things
<ul>
	<li>
		<details>
			<summary><h2>Memory API</h2></summary>
			Memory and file management
			<pre lang="lua">local MEM = require("rabbit.util.memory")</pre>
		</details>
		<ul>
			<li>
				<details>
					<summary>
						<code>MEM.<b>rel_path</b>(<i>target</i>)</code>
						→ table
						<br>
						Returns the relative path to the target file from the current file. Also handles trimming and overflows
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
									<td>target</td>
									<td>string</td>
									<td>/path/to/target</td>
								</tr>
							</table>
						</li>
						<li>
							<b>Returns</b>
							<table>
								<tr>
									<td>key</td>
									<td>type</td>
									<td>description</td>
								<tr>
									<td>dir</td>
									<td>string</td>
									<td>Dir part, eg <code>.../rel/to/</code></td>
								</tr>
								<tr>
									<td>name</td>
									<td>string</td>
									<td>Name part, eg <code>foo.txt</code></td>
								</tr>
							</table>
						</li>
					</ul>
				</details>
			</li>
		</ul>
	</li>
	<li>
		<details>
			<summary><h2>Set API</h2></summary>
			Treats tables like sets
			<pre lang="lua">local SET = require("rabbit.util.set")</pre>
		</details>
		<ul>
			<li>
				<details>
					<summary>
						<code>SET.<b>add</b>(<i>set</i>, <i>value</i>)</code><br>
						Prepends a value to a set, removing any duplicates
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
									<td>arr</td>
									<td><code>T</code>[]</td>
									<td>Set to prepend to</td>
								</tr>
								<tr>
									<td>value</td>
									<td><code>T</code></td>
									<td>Value to add to the front of the table</td>
								</tr>
							</table>
						</li>
						<li><i>Doesn't return anything</i></li>
					</ul>
				</details>
			</li>
			<li>
				<details>
					<summary>
						<code>SET.<b>sub</b>(<i>set</i>, <i>value</i>)</code>
						→ boolean
						<br>
						Removes a value from a set
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
									<td>arr</td>
									<td><code>T</code>[]</td>
									<td>Set to remove from</td>
								</tr>
								<tr>
									<td>value</td>
									<td><code>T</code></td>
									<td>Value to remove</td>
								</tr>
							</table>
						</li>
						<li>
							<b>Returns</b>
							<table>
								<tr>
									<td><code>boolean</code></td>
									<td>Whether anything was removed</td>
								</tr>
							</table>
						</li>
					</ul>
				</details>
			</li>
			<li>
				<details>
					<summary>
						<code>SET.<b>insert</b>(<i>set</i>, <i>value</i>, <i>idx?</i>)</code><br>
						Mirror of `table.insert`, but with extra typing
					</summary>
						Unforutately, luals doesn't even parse generics so this is useless for the time being
				</details>
			</li>
		</ul>
	</li>
	<li>
		<details>
			<summary><h2>Terminal API</h2></summary>
			Additional terminal functions
			<pre lang="lua">local TERM = require("rabbit.util.term")</pre>
		</details>
		<ul>
			<li>
				<details>
					<summary>
						<code>TERM.<b>wrap</b>(<i>text</i>, <i>width</i>)</code>
						→ string[]
						<br>
						Wraps text to a given width
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
									<td>text</td>
									<td>string</td>
									<td>Text to wrap</td>
								</tr>
								<tr>
									<td>width</td>
									<td>number</td>
									<td>Width to wrap to</td>
								</tr>
							</table>
						</li>
						<li>
							<b>Returns</b>
							<table>
								<tr>
									<td>string[]</td>
									<td>Wrapped text</td>
								</tr>
							</table>
						</li>
					</ul>
				</details>
			</li>
		</ul>
	</li>
</ul>



