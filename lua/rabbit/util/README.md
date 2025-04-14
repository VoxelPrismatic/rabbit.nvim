<h1>Rabbit Utilities API</h1>
Various APIs that are useful for various other things
<ul>
	<li>
		<details>
			<summary>
				<h2>Memory API</h2>
			</summary>
			Memory and file management
			<pre lang="lua">local MEM = require("rabbit.util.memory")</pre>
		</details>
		<ul>
			<li>
				<details>
					<summary>
						<code>MEM.<b>rel_path</b>(<i>target</i>)</code><br>
						→
						<i>Rabbit.Mem.RelPath</i>
						<br>
						Returns the relative path to the target file from the current file. Also handles trimming and
						overflows
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
									<th>-</th>
									<th>type</th>
									<th>description</th>
								</tr>
								<tr>
									<td>-&gt;</td>
									<td>
										Rabbit.Mem.RelPath:
										<table>
											<tr>
												<th>key</th>
												<th>type</th>
												<th>desc</th>
											</tr>
											<tr>
												<td>dir</td>
												<td>string</td>
												<td>Dir part, eg
													<code>.../rel/to/</code>
												</td>
											</tr>
											<tr>
												<td>name</td>
												<td>string</td>
												<td>Name part, eg
													<code>foo.txt</code>
												</td>
											</tr>
											<tr>
												<td>merge</td>
												<td>string</td>
												<td>The merged path, eg
													<code>.../rel/to/foo.txt</code>
												</td>
											</tr>
											<tr>
												<td>parts</td>
												<td>string[]</td>
												<td>The entire relative path from source to target, eg
													<code>{ "..", "..", "rel", "to", "foo.txt" }</code>
												</td>
											</tr>
											<tr>
												<td>source</td>
												<td>string</td>
												<td>Real, absolute path of the source file</td>
											</tr>
											<tr>
												<td>target</td>
												<td>string</td>
												<td>Real, absolute path of the target file</td>
											</tr>
											<tr>
												<td><i>[integer]</i></td>
												<td>Rabbit.Mem.RelPath</td>
												<td>Re-cast with a new maximum display width</td>
											</tr>
										</table>
									</td>
									<td>Relative filepath details</td>
								</tr>
							</table>
						</li>
					</ul>
				</details>
			</li>
			<li>
				<details>
					<summary>
						<code>MEM.<b>Read</b>(<i>src</i>)</code><br>
						→ table<br>
						2 boolean
						<br>
						Reads a JSON file
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
									<td>src</td>
									<td>string</td>
									<td>/path/to/file.json</td>
								</tr>
							</table>
						</li>
						<li>
							<b>Returns</b>
							<table>
								<tr>
									<th>-</th>
									<th>type</th>
									<th>description</th>
								</tr>
								<tr>
									<td>-&gt;</td>
									<td>table</td>
									<td>JSON data</td>
								</tr>
								<tr>
									<td>2</td>
									<td>boolean</td>
									<td>True if the file exists</td>
								</tr>
							</table>
						</li>
						<li>
							<b>Notes</b>
							<ol>
								<li>
									The returned JSON object is not
									<i>exactly</i>
									what's stored in the file. It also
									sets
									<code>__Dest</code>, the write destination, and
									<code>__Save()</code>, the save
									function.
									When
									<code>__Save</code>
									is called, the file will be saved to the destination,
									without
									needing to call
									<code>MEM.<b>Write</b></code>
								</li>
								<li>
									If the file does not exist, it will return
									<code>{}</code>
									under the assumption
									that it will be written to later
								</li>
							</ol>
						</li>
						<li>
							<b>Throws</b>
							<ol>
								<li>When the file is not JSON encoded</li>
								<li>When the file could not be read for another reason</li>
							</ol>
						</li>
					</ul>
				</details>
			</li>
			<li>
				<details>
					<summary>
						<code>MEM.<b>Write</b>(<i>data</i>,&nbsp;<i>dest</i>)</code>
						→ nil
						<br>
						Writes a JSON file
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
									<td>data</td>
									<td>table</td>
									<td>JSON data</td>
								</tr>
								<tr>
									<td>dest</td>
									<td>string</td>
									<td>/path/to/file.json</td>
								</tr>
							</table>
						</li>
						<li><i>Doesn't return anything</i></li>
						<li>
							<b>Throws</b>
							<ol>
								<li>When the file could not be written for another reason</li>
								<li>When the file is not JSON encoded</li>
								<li>When the table mixes integer and string keys
									<i>this is a Vim limitation</i>
								</li>
							</ol>
						</li>
						<li>
							<b>Notes</b>
							<ol>
								<li>
									This may not be called with the return value from
									<code>MEM.<b>Read</b></code>,
									as that return value includes some metadata that is not removed by this function.
									Instead, you must call
									<code>obj.<b>__Save()</b></code>
								</li>
							</ol>
						</li>
					</ul>
				</details>
			</li>
		</ul>
	</li>
	<li>
		<details>
			<summary>
				<h2>Set API</h2>
			</summary>
			Treats tables like sets
			<pre lang="lua">
				local SET = require("rabbit.util.set")
				local obj = SET.new()
			</pre>
		</details>
		<ul>
			<li>
				<details>
					<summary>
						<code>SET.<b>new</b>(<i>arr?</i>)</code>
						→
						<i>Rabbit.Table.Set</i>&lt;T&gt;
						<br>
						Creates a new set
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
									<td>arr?</td>
									<td>T[]</td>
									<td>Initial values (deepcopy &amp; unique</td>
								</tr>
							</table>
						</li>
						<li>
							<b>Returns</b>
							<table>
								<tr>
									<th>-</th>
									<th>type</th>
									<th>description</th>
								</tr>
								<tr>
									<td>-&gt;</td>
									<td><i>Rabbit.Table.Set</i>&lt;T&gt;</td>
									<td>The new set</td>
								</tr>
							</table>
						</li>
					</ul>
				</details>
			</li>
			<li>
				<details>
					<summary>
						<code>obj:<b>add</b>(<i>elem</i>,&nbsp;<i>idx?</i>)</code>
						→
						<i>Rabbit.Table.Set</i>&lt;T&gt;
						<br>
						Adds an element (or elements) to the set
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
									<td rowspan="2">elem</td>
									<td>T</td>
									<td>
										Add a single element. Any duplicate elements are removed and inserted at the
										target position
									</td>
								</tr>
								<tr>
									<td>T[]</td>
									<td>
										Adds many elements. Any duplicate elements are removed and inserted at the
										target position
									</td>
								</tr>
								<tr>
									<td rowspan="2">idx?</td>
									<td>integer</td>
									<td>
										Index to insert elements at. If negative, it adds at idx from the end.
										Eg, -1 for last, -2 for second to last
									</td>
								</tr>
								<tr>
									<td><i>nil</i></td>
									<td>Insert at the beginning</td>
								</tr>
							</table>
						</li>
						<li>
							<b>Returns</b>
							<table>
								<tr>
									<th>-</th>
									<th>type</th>
									<th>description</th>
								</tr>
								<tr>
									<td>-&gt;</td>
									<td><i>Rabbit.Table.Set</i>&lt;T&gt;</td>
									<td>Itself, for chaining</td>
								</tr>
							</table>
						</li>
					</ul>
				</details>
			</li>
			<li>
				<details>
					<summary>
						<code>obj:<b>pop</b>(<i>idx?</i>)</code>
						→ &lt;T&gt;
						<br>
						Removes an element from the set
					</summary>
			<li>
				<b>Parameters</b>
				<table>
					<tr>
						<th>param</th>
						<th>type</th>
						<th>details</th>
					</tr>
					<tr>
						<td>idx?</td>
						<td>integer</td>
						<td>
							Index to remove. If negative, it removes from idx from the end.
							Eg, -1 for last, -2 for second to last
						</td>
					</tr>
				</table>
			</li>
			<li>
				<b>Returns</b>
				<table>
					<tr>
						<th>-</th>
						<th>type</th>
						<th>description</th>
					</tr>
					<tr>
						<td>-&gt;</td>
						<td>T</td>
						<td>The removed element</td>
					</tr>
				</table>
			</li>
			</details>
	</li>
	<li>
		<details>
			<summary>
				<code>obj:<b>del</b>(<i>elem</i>)</code>
				→ integer
				<br>
				Removes an element from the set
</ul>
</li>
<li>
	<details>
		<summary>
			<h2>Terminal API</h2>
		</summary>
		Additional terminal functions
		<pre lang="lua">local TERM = require("rabbit.util.term")</pre>
	</details>
	<ul>
		<li>
			<details>
				<summary>
					<code>TERM.<b>wrap</b>(<i>text</i>,
						<i>width</i>)</code>
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
