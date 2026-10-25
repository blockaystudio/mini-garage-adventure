/* First-party compressed Godot engine delivery; no remote library or service. */
(() => {
  'use strict';
  const engineURL = new URL('index.wasm', document.baseURI);
  const packedURL = new URL('index.wasm.gz', document.baseURI);
  const originalFetch = window.fetch.bind(window);
  const expectedBytes = __GARAGE_WASM_BYTES__;
  window.fetch = async (input, init) => {
    const requested = new URL(input instanceof Request ? input.url : String(input), document.baseURI);
    if (requested.href !== engineURL.href) return originalFetch(input, init);
    if (typeof DecompressionStream !== 'function' || typeof TransformStream !== 'function') {
      throw new Error('Please update your browser to play this preview. Use Safari 16.4 or newer, or a current Chrome, Edge or Firefox.');
    }
    const response = await originalFetch(packedURL.href, init);
    if (!response.ok || !response.body) {
      throw new Error('The game engine could not download. Check your connection, then reload this page.');
    }
    const reader = response.body.getReader();
    const initialChunks = [];
    let prefixLength = 0;
    while (prefixLength < 4) {
      const chunk = await reader.read();
      if (chunk.done || !chunk.value) {
        reader.cancel();
        throw new Error('The game download was incomplete. Please reload.');
      }
      initialChunks.push(chunk.value);
      prefixLength += chunk.value.length;
    }
    const signature = new Uint8Array(4);
    let offset = 0;
    for (const chunk of initialChunks) {
      const count = Math.min(4 - offset, chunk.length);
      signature.set(chunk.subarray(0, count), offset);
      offset += count;
      if (offset === 4) break;
    }
    const zipped = signature[0] === 0x1f && signature[1] === 0x8b;
    const wasm = signature[0] === 0 && signature[1] === 0x61 && signature[2] === 0x73 && signature[3] === 0x6d;
    if (!zipped && !wasm) {
      reader.cancel();
      throw new Error('The game download was not recognized. Sign in to your private Site, then reload.');
    }
    // Some hosts already decode Content-Encoding:gzip. Inspect the first bytes
    // rather than decompressing a host-decoded WASM stream a second time.
    const source = new ReadableStream({
      start(controller) { for (const chunk of initialChunks) controller.enqueue(chunk); },
      async pull(controller) {
        const chunk = await reader.read();
        if (chunk.done) controller.close();
        else controller.enqueue(chunk.value);
      },
      cancel(reason) { return reader.cancel(reason); }
    });
    let received = 0;
    const bounded = new TransformStream({
      transform(chunk, controller) {
        received += chunk.byteLength;
        if (received > expectedBytes) throw new Error('The game download exceeded its expected size. Please reload.');
        controller.enqueue(chunk);
      },
      flush() {
        if (received !== expectedBytes) throw new Error('The game download was incomplete. Please reload.');
      }
    });
    const decoded = (zipped ? source.pipeThrough(new DecompressionStream('gzip')) : source).pipeThrough(bounded);
    return new Response(decoded, {
      status: 200,
      headers: { 'Content-Type': 'application/wasm', 'Content-Length': String(expectedBytes) }
    });
  };
})();
