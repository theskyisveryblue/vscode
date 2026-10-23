/*---------------------------------------------------------------------------------------------
 *  Copyright (c) Microsoft Corporation. All rights reserved.
 *  Licensed under the MIT License. See License.txt in the project root for license information.
 *--------------------------------------------------------------------------------------------*/

// Fast utility functions - optimized versions with reduced delays
// Use by setting VSCODE_FAST_WATCH=1 environment variable

import * as es from 'event-stream';
import _debounce = require('debounce');
import { ThroughStream } from 'through';

export interface ICancellationToken {
	isCancellationRequested(): boolean;
}

const NoCancellationToken: ICancellationToken = { isCancellationRequested: () => false };

export interface IStreamProvider {
	(cancellationToken?: ICancellationToken): NodeJS.ReadWriteStream;
}

// Fast incremental compilation with reduced debounce (200ms instead of 500ms)
const FAST_DEBOUNCE_DELAY = 200;

export function incrementalFast(streamProvider: IStreamProvider, initial: NodeJS.ReadWriteStream, supportsCancellation?: boolean): NodeJS.ReadWriteStream {
	const input = es.through();
	const output = es.through();
	let state = 'idle';
	let buffer = Object.create(null);

	const token: ICancellationToken | undefined = !supportsCancellation ? undefined : { isCancellationRequested: () => Object.keys(buffer).length > 0 };

	const run = (input: NodeJS.ReadWriteStream, isCancellable: boolean) => {
		state = 'running';

		const stream = !supportsCancellation ? streamProvider() : streamProvider(isCancellable ? token : NoCancellationToken);

		input
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

	input.on('data', (f: any) => {
		buffer[f.path] = f;

		if (state === 'idle') {
			eventuallyRun();
		}
	});

	return es.duplex(input, output);
}

// Fast debounce function with reduced delay
export function debounceFast(task: () => NodeJS.ReadWriteStream, duration = FAST_DEBOUNCE_DELAY): NodeJS.ReadWriteStream {
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





