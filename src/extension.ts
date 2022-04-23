import * as vscode from 'vscode';
import { CalsTableView, UpdateViewType } from './calsTableView';

export function activate(context: vscode.ExtensionContext) {
	let calsTableView: CalsTableView | undefined;
	context.subscriptions.push(
		vscode.commands.registerCommand('calsViewer.open', () => {
			calsTableView = CalsTableView.createOrShow(context.extensionUri, UpdateViewType.fileAppend);
		}),
		vscode.commands.registerCommand('calsViewer.openDirectory', () => {
			calsTableView = CalsTableView.createOrShow(context.extensionUri, UpdateViewType.directory);
		})
	);
	context.subscriptions.push(vscode.window.onDidChangeActiveTextEditor(editor => {
		if (calsTableView) {
			calsTableView.updateViewSource(editor);
		}
	}));

	if (vscode.window.registerWebviewPanelSerializer) {
		// Make sure we register a serializer in activation event
		vscode.window.registerWebviewPanelSerializer(CalsTableView.viewType, {
			async deserializeWebviewPanel(webviewPanel: vscode.WebviewPanel, state: any) {
				// Reset the webview options so we use latest uri for `localResourceRoots`.
				webviewPanel.webview.options = getWebviewOptions(context.extensionUri);
				CalsTableView.revive(webviewPanel, context.extensionUri);
			}
		});
	}
}

function getWebviewOptions(extensionUri: vscode.Uri): vscode.WebviewOptions {
	return {
		// Enable javascript in the webview
		enableScripts: true,

		// And restrict the webview to only loading content from our extension's `media` and 'saxon' directories.
		localResourceRoots: [
			vscode.Uri.joinPath(extensionUri, 'media'),
			vscode.Uri.joinPath(extensionUri, 'saxon')
		]
	};
}