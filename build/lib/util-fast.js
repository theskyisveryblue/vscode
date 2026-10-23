/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

// Fast utility functions - optimized versions with reduced delays
// Use by setting VSCODE_FAST_WATCH=1 environment variable

const es = require('event-stream');
const _debounce = require('debounce');

// Fast incremental compilation with reduced debounce (150ms for even faster feedback)
const FAST_DEBOUNCE_DELAY = 150;

function incrementalFast(streamProvider, initial, supportsCancellation) {
	const input = es.through();
	const output = es.through();
	let state = 'idle';
	let buffer = Object.create(null);

	const token = !supportsCancellation ? undefined : { isCancellationRequested: () => Object.keys(buffer).length > 0 };

	const run = (inputStream, isCancellable) => {
		state = 'running';

		const stream = !supportsCancellation ? streamProvider() : streamProvider(isCancellable ? token : { isCancellationRequested: () => false });

		inputStream
			.pipe(stream)
			.pipe(es.through(undefined, () => {
				state = 'idle';
				eventuallyRun();
			}))
			.pipe(output);
	};

	if (initial) {
		run(initial, false);
	}

	// Fast debounce: 200ms instead of 500ms
	const eventuallyRun = _debounce(() => {
		const paths = Object.keys(buffer);

		if (paths.length === 0) {
			return;
		}

		const data = paths.map(path => buffer[path]);
		buffer = Object.create(null);
		run(es.readArray(data), true);
	}, FAST_DEBOUNCE_DELAY);

	input.on('data', (f) => {
		buffer[f.path] = f;

		if (state === 'idle') {
			eventuallyRun();
		}
	});

	return es.duplex(input, output);
}

function debounceFast(task, duration = FAST_DEBOUNCE_DELAY) {
	const input = es.through();
	const output = es.through();
	let state = 'idle';

	const run = () => {
		state = 'running';

		task()
			.pipe(es.through(undefined, () => {
				const shouldRunAgain = state === 'stale';
				state = 'idle';

				if (shouldRunAgain) {
					eventuallyRun();
				}
			}))
			.pipe(output);
	};

	run();

	const eventuallyRun = _debounce(() => {
		if (state === 'idle') {
			run();
		} else {
			state = 'stale';
		}
	}, duration);

	input.on('data', () => {
		eventuallyRun();
	});

	return es.duplex(input, output);
}

module.exports = {
	incrementalFast,
	debounceFast
};

