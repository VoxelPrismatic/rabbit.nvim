# Configuration

Rabbit is quite advanced, so read the types carefully.

## Types

<ul>
	<li>
		<details>
			<summary>
				<h3>NvimHlKwargs</h3>
			</summary>
			This mirrors <code>vim.api.keyset.highlight</code>, but has some fancy features.
			<table>
				<tr>
					<th>-</th>
					<th>key</th>
					<th>type</th>
					<th>description</th>
				</tr>
				<tr>
					<td rowspan="5">colors</td>
					<td>fg?</td>
					<td>string</td>
					<td>
						Foreground color
						<ul>
							<li><code>#RRGGBB</code> - Hex color</li>
							<li><code>:HlGroupName</code> - Samples the foreground color from <code>HlGroupName</code></li>
							<li><code>:HlGroupName#prop</code> - Sampes the <code>prop</code> color from <code>HlGroupName</code></li>
						</ul>
					</td>
				</tr>
				<tr>
					<td>bg?</td>
					<td>string</td>
					<td>
						Background color
						<ul>
							<li><code>#RRGGBB</code> - Hex color</li>
							<li><code>:HlGroupName</code> - Samples the background color from <code>HlGroupName</code></li>
							<li><code>:HlGroupName#prop</code> - Sampes the <code>prop</code> color from <code>HlGroupName</code></li>
						</ul>
					</td>
				</tr>
				<tr>
					<td>sp?</td>
					<td>string</td>
					<td>
						Special color (underlines)
						<ul>
							<li><code>#RRGGBB</code> - Hex color</li>
							<li><code>:HlGroupName</code> - Samples the special color from <code>HlGroupName</code></li>
							<li><code>:HlGroupName#prop</code> - Sampes the <code>prop</code> color from <code>HlGroupName</code></li>
						</ul>
					</td>
				</tr>
				<tr>
					<td>ctermfg?</td>
					<td>integer</td>
					<td>ANSI foreground color, as set by the host terminal emulator instead of Neovim</td>
				</tr>
				<tr>
					<td>ctermbg?</td>
					<td>integer</td>
					<td>ANSI background color, as set by the host terminal emulator instead of Neovim</td>
				</tr>
				<tr>
					<td rowspan="11">styles</td>
					<td>bold?</td>
					<td>boolean</td>
					<td><b>Bold</b> text</td>
				</tr>
				<tr>
					<td>italic?</td>
					<td>boolean</td>
					<td><i>Italic</i> text</td>
				</tr>
				<tr>
					<td>strikethrough?</td>
					<td>boolean</td>
					<td><s>Strikethrough</s> text</td>
				</tr>
				<tr>
					<td>underline?</td>
					<td>boolean</td>
					<td><u>Underline</u> text</td>
				</tr>
				<tr>
					<td>undercurl?</td>
					<td>boolean</td>
					<td>U᪶nd᪶er᪶cu᪶r᪶l text</td>
				</tr>
				<tr>
					<td>underdouble?</td>
					<td>boolean</td>
					<td>U͇n͇d͇e͇r͇d͇o͇u͇b͇l͇e͇ text</td>
				</tr>
				<tr>
					<td>underdotted?</td>
					<td>boolean</td>
					<td>Ṳn̤d̤e̤r̤d̤o̤t̤t̤e̤d̤ text</td>
				</tr>
				<tr>
					<td>underdashed?</td>
					<td>boolean</td>
					<td>U̱ṉḏe̱ṟḏa̱s̱ẖe̱ḏ text</td>
				</tr>
				<tr>
					<td>reverse?</td>
					<td>boolean</td>
					<td>Reverse foreground and background colors</td>
				</tr>
				<tr>
					<td>standout?</td>
					<td>boolean</td>
					<td>Standout text. Usually displayed as <code>reverse</code></td>
				</tr>
				<tr>
					<td>nocombine?</td>
					<td>boolean</td>
					<td>Do not combine special text decorations (underlines & strikes)</td>
				</tr>
				<tr>
					<td rowspan="5"></td>
					<td>cterm?</td>
					<td>string[]</td>
					<td>
						Zero to many of:
						<ul>
							<li><code>bold</code></li>
							<li><code>underline</code></li>
							<li><code>undercurl</code></li>
							<li><code>underdouble</code></li>
							<li><code>underdotted</code></li>
							<li><code>underdashed</code></li>
							<li><code>strikethrough</code></li>
							<li><code>inverse</code> (alias of <code>reverse</code>)</li>
							<li><code>reverse</code></li>
							<li><code>italic</code></li>
							<li><code>standout</code></li>
							<li><code>altfont</code></li>
							<li><code>nocombine</code></li>
						</ul>
						This is a legacy option which passes rendering onto the terminal emulator instead of Neovim.
						Please use the boolean options above instead for best results.
					</td>
				</tr>
				<tr>
					<td>blend?</td>
					<td>integer</td>
					<td>Background blend/opacity percentage (0-100%)</td>
				</tr>
				<tr>
					<td>link?</td>
					<td>string</td>
					<td>Link to another highlight group</td>
				</tr>
				<tr>
					<td>default?</td>
					<td>boolean</td>
					<td>If the highlight group exists, nothing will be changed</td>
				</tr>
				<tr>
					<td>force?</td>
					<td>boolean</td>
                    <td>Clear the existing higlight group before applying new values</td>
				</tr>
			</table>
		</details>
	</li>
</ul>
