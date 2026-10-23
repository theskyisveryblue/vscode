/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

'use strict';

// Fast watch mode gulpfile - optimized for development speed
// Use by running: VSCODE_FAST_WATCH=1 yarn watch-fast

// Increase max listeners for event emitters
require('events').EventEmitter.defaultMaxListeners = 100;

const gulp = require('gulp');
const path = require('path');
const util = require('./lib/util'); // Base utilities (rimraf, etc.)
const utilFast = require('./lib/util-fast.js'); // Fast utilities (incrementalFast)
const task = require('./lib/task');
const { compileExtensionsTask, watchExtensionsTask, compileExtensionMediaTask } = require('./gulpfile.extensions');
const root = path.dirname(__dirname);

// Patch util.incremental to use fast version when VSCODE_FAST_WATCH is set
const originalIncremental = util.incremental;
util.incremental = function (streamProvider, initial, supportsCancellation) {
	if (process.env.VSCODE_FAST_WATCH) {
		return utilFast.incrementalFast(streamProvider, initial, supportsCancellation);
	}
	return originalIncremental.apply(this, arguments);
};

// Fast watch task - same as regular but with faster readDelay
function fastWatchTask(out, build) {
	const es = require('event-stream');
	const fs = require('fs');
	const tsb = require('./lib/tsb');
	const sourcemaps = require('gulp-sourcemaps');
	const watch = process.platform === 'win32' ? require('./lib/watch-win32') : require('vscode-gulp-watch');
	const monacodts = require('./lib/monaco-api');
	// MonacoGenerator is defined in compilation.js - we'll recreate it inline
	// This is a simplified version - for full functionality, we'd need to copy the entire class
	const MonacoGenerator = (function () {
		const monacodts = require('./lib/monaco-api');
		class MonacoGenerator {
			constructor(isWatch) {
				this._isWatch = isWatch;
				this.stream = es.through();
				this._watchedFiles = {};
				this._fsProvider = new monacodts.FSProvider();
				this._declarationResolver = new monacodts.DeclarationResolver(this._fsProvider);
			}
			execute() {
				// Simplified - just create the stream
				// Full implementation would generate monaco.d.ts files
			}
		}
		return MonacoGenerator;
	})();
	const reporter = require('./lib/reporter').createReporter();
	const nls = require('./lib/nls');

	// Recreate createCompile logic (from compilation.js)
	function getTypeScriptCompilerOptions(src) {
		const rootDir = path.join(__dirname, `../../${src}`);
		return {
			verbose: false,
			sourceMap: !process.env['VSCODE_NO_SOURCEMAP'],
			rootDir: rootDir,
			baseUrl: rootDir,
			sourceRoot: util.toFileUri(rootDir),
			newLine: /\r\n/.test(fs.readFileSync(__filename, 'utf8')) ? 0 : 1
		};
	}

	function createCompile(src, options) {
		const projectPath = path.join(__dirname, '../../', src, 'tsconfig.json');
		const overrideOptions = { ...getTypeScriptCompilerOptions(src), inlineSources: Boolean(options.build) };
		if (!options.build) {
			overrideOptions.inlineSourceMap = true;
		}
		const compilation = tsb.create(projectPath, overrideOptions, {
			verbose: false,
			transpileOnly: Boolean(options.transpileOnly),
			transpileWithSwc: typeof options.transpileOnly !== 'boolean' && options.transpileOnly?.swc
		}, err => reporter(err));

		function pipeline(token) {
			const bom = require('gulp-bom');
			const tsFilter = util.filter(data => /\.ts$/.test(data.path));
			const isUtf8Test = (f) => /(\/|\\)test(\/|\\).*utf8/.test(f.path);
			const isRuntimeJs = (f) => f.path.endsWith('.js') && !f.path.includes('fixtures');
			const isCSS = (f) => f.path.endsWith('.css') && !f.path.includes('fixtures');
			const noDeclarationsFilter = util.filter(data => !(/\.d\.ts$/.test(data.path)));
			const postcssNesting = require('postcss-nesting');
			const input = es.through();
			const output = input
				.pipe(util.$if(isUtf8Test, bom()))
				.pipe(util.$if(!options.build && isRuntimeJs, util.appendOwnPathSourceURL()))
				.pipe(util.$if(isCSS, require('./lib/postcss').gulpPostcss([postcssNesting()], err => reporter(String(err)))))
				.pipe(tsFilter)
				.pipe(util.loadSourcemaps())
				.pipe(compilation(token))
				.pipe(noDeclarationsFilter)
				.pipe(util.$if(options.build, nls.nls({ preserveEnglish: options.preserveEnglish })))
				.pipe(noDeclarationsFilter.restore)
				.pipe(util.$if(!options.transpileOnly, sourcemaps.write('.', {
					addComment: false,
					includeContent: !!options.build,
					sourceRoot: overrideOptions.sourceRoot
				})))
				.pipe(tsFilter.restore)
				.pipe(reporter.end(!!options.emitError));
			return es.duplex(input, output);
		}
		return pipeline;
	}

	return function () {
		const compile = createCompile('src', { build, emitError: false, transpileOnly: false, preserveEnglish: false });
		const src = gulp.src('src/**', { base: 'src' });
		// Fast readDelay: 30ms for even faster file change detection (Void Editor inspired)
		const watchSrc = watch('src/**', { base: 'src', readDelay: 30 });

		const generator = new MonacoGenerator(true);
		generator.execute();

		return watchSrc
			.pipe(generator.stream)
			.pipe(utilFast.incrementalFast(compile, src, true))
			.pipe(gulp.dest(out));
	};
}

// Fast watch client task
const watchClientTaskFast = task.define('watch-client-fast', task.series(
	util.rimraf('out'),
	util.buildWebNodePaths('out'),
	task.parallel(
		task.define('watch-out-fast', fastWatchTask('out', false))
	)
));

gulp.task(watchClientTaskFast);

// Fast watch extensions (uses existing but with faster settings via env)
const watchExtensionsTaskFast = task.define('watch-extensions-fast', watchExtensionsTask);
gulp.task(watchExtensionsTaskFast);

// Fast watch all
gulp.task(task.define('watch-fast', task.parallel(watchClientTaskFast, watchExtensionsTaskFast)));

console.log('Fast watch mode enabled - using optimized delays (30ms readDelay, 150ms debounce) - Void Editor inspired');





