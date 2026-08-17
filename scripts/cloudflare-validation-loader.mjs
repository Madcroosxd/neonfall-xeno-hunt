const cloudflareWorkersStub = [
  "export const env = {};",
  "export const exports = {};",
  "export const cache = {};",
  "export const tracing = {};",
].join("\n");

export async function resolve(specifier, context, nextResolve) {
  if (specifier === "cloudflare:workers") {
    return {
      url: `data:text/javascript,${encodeURIComponent(cloudflareWorkersStub)}`,
      shortCircuit: true,
    };
  }

  return nextResolve(specifier, context);
}
