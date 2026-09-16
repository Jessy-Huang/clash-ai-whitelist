// Clash Verge Rev Global Extend Script
// Managed by clash-ai-whitelist
// Purpose: proxy selected AI / algorithm-engineering services, DIRECT everything else.

const PREFERRED_GROUP = "__PREFERRED_GROUP__";

const EXACT_DOMAINS = [
  "challenges.cloudflare.com",
  "gemini.google.com",
  "aistudio.google.com",
  "ai.google.dev",
  "generativelanguage.googleapis.com",
  "accounts.google.com",
  "apis.google.com",
  "colab.research.google.com",
  "marketplace.visualstudio.com",
  "update.code.visualstudio.com",
  "code.visualstudio.com",
  "ngc.nvidia.com",
  "catalog.ngc.nvidia.com",
  "developer.nvidia.com"
];

const SUFFIX_DOMAINS = [
  "chatgpt.com","openai.com","oaistatic.com","oaiusercontent.com","oaistatsig.com","openaimerge.com","workos.com","workoscdn.com",
  "github.com","githubusercontent.com","githubassets.com","githubcopilot.com","github.dev","ghcr.io",
  "huggingface.co","hf.co",
  "claude.ai","claude.com","anthropic.com",
  "gstatic.com","googleusercontent.com","colab.google",
  "grok.com","x.ai",
  "openrouter.ai","together.ai","groq.com","mistral.ai","replicate.com","perplexity.ai","cohere.com",
  "cursor.com","cursor.sh","windsurf.com","codeium.com","sourcegraph.com",
  "vsassets.io",
  "docker.io","docker.com","dockerstatic.com",
  "nvcr.io",
  "pypi.org","pythonhosted.org","npmjs.org","npmjs.com","crates.io","anaconda.org","conda.io",
  "wandb.ai",
  "gitlab.com","gitlab-static.net",
  "runpod.io","modal.com","vast.ai","lambda.ai",
  "arxiv.org","openreview.net","paperswithcode.com","semanticscholar.org","kaggle.com","kaggleusercontent.com",
  "pytorch.org","tensorflow.org"
];

function groups(config) {
  return Array.isArray(config["proxy-groups"]) ? config["proxy-groups"] : [];
}

function groupExists(config, name) {
  return groups(config).some(g => g && g.name === name);
}

function chooseProxyGroup(config) {
  if (PREFERRED_GROUP && groupExists(config, PREFERRED_GROUP)) return PREFERRED_GROUP;
  const gs = groups(config);
  const namePatterns = [/选择节点/i,/节点选择/i,/代理节点/i,/proxy/i,/select/i,/manual/i];
  for (const re of namePatterns) {
    const hit = gs.find(g => g && g.type === "select" && re.test(String(g.name || "")));
    if (hit) return hit.name;
  }
  const firstSelect = gs.find(g => g && g.type === "select" && g.name);
  if (firstSelect) return firstSelect.name;
  const first = gs.find(g => g && g.name);
  return first ? first.name : null;
}

function main(config, profileName) {
  const proxyGroup = chooseProxyGroup(config);
  if (!proxyGroup) {
    console.log("[clash-ai-whitelist] No proxy group found; leaving config unchanged.");
    return config;
  }
  const managedRules = [
    ...EXACT_DOMAINS.map(d => `DOMAIN,${d},${proxyGroup}`),
    ...SUFFIX_DOMAINS.map(d => `DOMAIN-SUFFIX,${d},${proxyGroup}`),
    "MATCH,DIRECT"
  ];
  config["rules"] = managedRules;
  console.log(`[clash-ai-whitelist] profile=${profileName || "unknown"} group=${proxyGroup} rules=${managedRules.length}`);
  return config;
}
