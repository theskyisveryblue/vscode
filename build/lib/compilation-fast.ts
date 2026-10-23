/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

// Fast compilation mode - optimized for development speed
// Use by setting VSCODE_FAST_WATCH=1 environment variable

import * as gulp from 'gulp';
import * as path from 'path';
import * as util from './util';
import * as task from './task';
import { createCompile } from './compilation';
import { MonacoGenerator } from './monacoGenerator';
const watch = process.platform === 'win32' ? require('./watch-win32') : require('vscode-gulp-watch');

// Fast mode settings: reduced delays for faster feedback (Void Editor inspired optimizations)
const FAST_READ_DELAY = 30;  // Reduced from 50ms for even faster file change detection
const FAST_DEBOUNCE = 150;   // Reduced from 200ms for quicker compilation feedback

export function fastWatchTask(out: string, build: boolean): task.StreamTask {
	const task = () => {
		const compile = createCompile('src', { build, emitError: false, transpileOnly: false, preserveEnglish: false });

		const src = gulp.src('src/**', { base: 'src' });
		// Use faster readDelay for quicker file change detection
		const watchSrc = watch('src/**', { base: 'src', readDelay: FAST_READ_DELAY });

		const generator = new MonacoGenerator(true);
		generator.execute();

		// Use faster incremental compilation with reduced debounce
		return watchSrc
			.pipe(generator.stream)
			.pipe(util.incrementalFast(compile, src, true))
			.pipe(gulp.dest(out));
	};
	task.taskName = `watch-fast-${path.basename(out)}`;
	return task;
}





