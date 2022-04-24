import { pathToFileURL } from 'url';
import { TextDecoder } from 'util';
import * as vscode from 'vscode';

enum OutputMethod {
	append = 'append',
	replace = 'replace',
	clear = 'clear'
}

interface ViewerMessage {
	command: string,
	sourceText: string[],
	sourceFilename: string[],
	method: OutputMethod
}

export enum UpdateViewType {
	fileAppend,
	fileReplace,
	directory
}

type FileDescriptor = [string, vscode.FileType];

export class CalsTableView {
	/**
	 * Track the current panel. Only allow a single panel to exist at a time.
	 * Show an aggregate view of files visited since panel was first shown
	 */
	public static currentPanel: CalsTableView | undefined;

	public static readonly viewType = 'calsViewer';
	private static readonly viewerTitle = 'CALS Table Viewer';
	private static readonly macosStore = '.DS_Store';
	private readonly _panel: vscode.WebviewPanel;
	private readonly _extensionUri: vscode.Uri;
	private static updateViewType: UpdateViewType;
	private initialized = false;
	private _disposables: vscode.Disposable[] = [];
	private sourcePaths: vscode.Uri[] = [];
	private sourceTexts: string[] = [];
	private sefURI = '';

	public static createOrShow(extensionUri: vscode.Uri, updateViewType: UpdateViewType) {
		const activeEditor: vscode.TextEditor | undefined = vscode.window.activeTextEditor;
		const column = activeEditor
			? vscode.ViewColumn.Beside
			: undefined;

		// If we already have a panel, show it.
		if (this.currentPanel) {
			const reset = CalsTableView.updateViewType !== updateViewType || CalsTableView.updateViewType === UpdateViewType.directory;
			if (reset) {
				this.currentPanel.clearFileHistory();
			}
			CalsTableView.updateViewType = updateViewType;
			this.currentPanel.refreshView();
			if (activeEditor) this.currentPanel.updateForViewType(activeEditor, reset);
		} else {
			// Otherwise, create a new panel.
			CalsTableView.updateViewType = updateViewType;
			const panel = vscode.window.createWebviewPanel(
				CalsTableView.viewType,
				CalsTableView.viewerTitle,
				{ viewColumn: column || vscode.ViewColumn.One, preserveFocus: true },
				CalsTableView.getWebviewOptions(extensionUri),
			);
			CalsTableView.currentPanel = new CalsTableView(panel, extensionUri, activeEditor,);
		}

		return CalsTableView.currentPanel;
	}

	public static revive(panel: vscode.WebviewPanel, extensionUri: vscode.Uri) {
		CalsTableView.currentPanel = new CalsTableView(panel, extensionUri);
	}

	private static filenameFromPath(fullPath: vscode.Uri) {
		const fPath = fullPath.fsPath;
		const pos = fPath.lastIndexOf('/');
		const fileName = pos > -1 ? fPath.substring(pos + 1) : fPath;
		return fileName;
	}

	public clearFileHistory() {
		this.sourcePaths = [];
		this.sourceTexts = [];
	}

	private constructor(panel: vscode.WebviewPanel, extensionUri: vscode.Uri, activeEditor?: vscode.TextEditor | undefined) {
		this._panel = panel;
		this._extensionUri = extensionUri;
		const stylesSefPath = vscode.Uri.joinPath(this._extensionUri, 'saxon', 'style-tables.sef.json');
		this.sefURI = this._panel.webview.asWebviewUri(stylesSefPath).toString();

		// Set the webview's initial html content
		this._panel.webview.html = this._getHtmlForWebview(this._panel.webview);

		// Listen for when the panel is disposed
		// This happens when the user closes the panel or when the panel is closed programmatically
		this._panel.onDidDispose(() => this.dispose(), null, this._disposables);

		if (activeEditor) this.updateForViewType(activeEditor);

		// Handle messages from the webview
		this._panel.webview.onDidReceiveMessage(
			message => {
				switch (message.command) {
					case 'alert':
						vscode.window.showErrorMessage(message.text);
						return;
				}
			},
			null,
			this._disposables
		);

		// Update the content based on view changes
		this._panel.onDidChangeViewState(
			e => {
				if (this._panel.visible && this.initialized) {
					const renew = false;
					this.updateAll(renew);
				}
				this.initialized = true;
			},
			null,
			this._disposables
		);
	}

	private updateForViewType(activeEditor: vscode.TextEditor, resetView?: boolean) {
		switch (CalsTableView.updateViewType) {
			case UpdateViewType.fileAppend:
			case UpdateViewType.fileReplace:
				this.updateViewSource(activeEditor, resetView);
				break;
			case UpdateViewType.directory:
				if (activeEditor) {
					this.updateDirectorySourcePaths(activeEditor);
				}
				break;
		}
	}

	public refreshView() {
		if (CalsTableView.currentPanel) {
			const preserveFocus = true;
			const activeEditor: vscode.TextEditor | undefined = vscode.window.activeTextEditor;
			const column = activeEditor
				? vscode.ViewColumn.Beside
				: undefined;
			CalsTableView.currentPanel._panel.reveal(column, preserveFocus);
			return true;
		} else {
			return false;
		}
	}

	private postMessageToViewer(message: ViewerMessage) {
		this._panel.webview.postMessage(message);
	}

	public updateViewSource(editor: vscode.TextEditor | undefined, reset?: boolean) {
		if (editor && CalsTableView.updateViewType !== UpdateViewType.directory) {
			const fullPath = editor.document.uri;
			let outputMethod = CalsTableView.updateViewType === UpdateViewType.fileAppend ?
				OutputMethod.append :
				OutputMethod.replace;
			if (reset) {
				outputMethod = OutputMethod.replace;
			}
			if (CalsTableView.updateViewType === UpdateViewType.fileReplace) {
				this.clearFileHistory();
			}
			// append content if new file path is not the same as the last path:
			if (this.sourcePaths.length === 0 || this.sourcePaths[this.sourcePaths.length - 1].fsPath !== fullPath.fsPath) {
				this.sourcePaths.push(fullPath);
				const sourceText = editor.document.getText();
				this.sourceTexts.push(sourceText);
				const sourceFilename = CalsTableView.filenameFromPath(fullPath);

				this.postMessageToViewer({
					command: 'update',
					sourceText: [sourceText],
					sourceFilename: [sourceFilename],
					method: outputMethod
				});
			}
		}
	}

	private async updateAll(renewSourceTexts: boolean) {
		const newSourceTexts: string[] = [];
		if (renewSourceTexts) {
			for (let index = 0; index < this.sourcePaths.length; index++) {
				const sourcePath = this.sourcePaths[index];
				const sourceArray = await vscode.workspace.fs.readFile(sourcePath);
				const sourceText = new TextDecoder().decode(sourceArray);
				newSourceTexts.push(sourceText);
			}
			this.sourceTexts = newSourceTexts;
		}

		this.postMessageToViewer({
			command: 'update',
			sourceText: this.sourceTexts,
			sourceFilename: this.sourcePaths.map((fullPath) => CalsTableView.filenameFromPath(fullPath)),
			method: OutputMethod.replace
		});
	}

	public dispose() {
		CalsTableView.currentPanel = undefined;

		// Clean up our resources
		this._panel.dispose();

		while (this._disposables.length) {
			const x = this._disposables.pop();
			if (x) {
				x.dispose();
			}
		}
	}

	private getNonce() {
		let text = '';
		const possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
		for (let i = 0; i < 32; i++) {
			text += possible.charAt(Math.floor(Math.random() * possible.length));
		}
		return text;
	}

	private async updateDirectorySourcePaths(activeEditor: vscode.TextEditor) {
		const uri = activeEditor.document.uri;
		const uriPath = uri.path;
		const pos = uriPath.lastIndexOf('/');
		if (pos > -1) {
			const directoryPath = uriPath.substring(0, pos);
			const directoryUri = uri.with({ path: directoryPath });
			const unsortedFileDataPairs: FileDescriptor[] = await vscode.workspace.fs.readDirectory(directoryUri);
			const fileDataPairs = unsortedFileDataPairs.sort(CalsTableView.sortFiles);
			const fileUris: vscode.Uri[] = [];
			fileDataPairs.forEach((pair) => {
				const [fileName, fileType] = pair;
				if (fileType === vscode.FileType.File && fileName !== CalsTableView.macosStore) {
					const fileUri = directoryUri.with({ path: directoryPath + '/' + fileName });
					fileUris.push(fileUri);
				}
			});
			this.sourcePaths = fileUris;
			const renewSourceTexts = true;
			this.updateAll(renewSourceTexts);
		}
	}

	private static sortFiles = (a: FileDescriptor, b: FileDescriptor) => {
		const [nameA, typeA] = a;
		const [nameB, typeB] = b;
		return nameA.localeCompare(nameB, 'en', { numeric: true });
	}

	private static getWebviewOptions(extensionUri: vscode.Uri): vscode.WebviewOptions {
		return {
			// Enable javascript in the webview
			enableScripts: true,

			// And restrict the webview to only loading content from our extension's `media` directory.
			localResourceRoots: [
				vscode.Uri.joinPath(extensionUri, 'media'),
				vscode.Uri.joinPath(extensionUri, 'saxon')
			]
		};
	}

	private _getHtmlForWebview(webview: vscode.Webview) {
		// Local path to main script run in the webview
		const scriptPathOnDisk = vscode.Uri.joinPath(this._extensionUri, 'media', 'main.js');
		const scriptSaxonPathOnDisk = vscode.Uri.joinPath(this._extensionUri, 'saxon', 'SaxonJS2.rt.js');

		// And the uri we use to load this script in the webview
		const scriptUri = (scriptPathOnDisk).with({ 'scheme': 'vscode-resource' });
		const scriptSaxonUri = (scriptSaxonPathOnDisk).with({ 'scheme': 'vscode-resource' });

		// Local path to css styles
		const styleResetPath = vscode.Uri.joinPath(this._extensionUri, 'media', 'reset.css');
		const stylesPathMainPath = vscode.Uri.joinPath(this._extensionUri, 'media', 'vscode.css');
		// Uri to load styles into webview
		const stylesResetUri = webview.asWebviewUri(styleResetPath);
		const stylesMainUri = webview.asWebviewUri(stylesPathMainPath);

		// Use a nonce to only allow specific scripts to be run
		const nonce = this.getNonce();

		return `<!DOCTYPE html>
			<html lang="en">
			<head>
				<meta charset="UTF-8">

				<!--
					Use a content security policy to only allow loading images from https or from our extension directory,
					and only allow scripts that have a specific nonce.
				-->
				<meta http-equiv="Content-Security-Policy" content="default-src 'none'; style-src ${webview.cspSource}; connect-src ${webview.cspSource}; img-src ${webview.cspSource} https:; script-src 'nonce-${nonce}';">

				<meta name="viewport" content="width=device-width, initial-scale=1.0">

				<link href="${stylesResetUri}" rel="stylesheet">
				<link href="${stylesMainUri}" rel="stylesheet">

				<title>CALS Table Viewer</title>
			</head>
			<body>
				<div id="main"></div>
				<div id="end"></div>
				<script nonce="${nonce}">var saxonData = {'sef': ${JSON.stringify(this.sefURI)}}</script>
				<script nonce="${nonce}" src="${scriptSaxonUri}"></script>
				<script nonce="${nonce}" src="${scriptUri}"></script>
			</body>
			</html>`;
	}
}
