_: {
  services = {
    ollama = {
      enable = true;
      acceleration = "cuda";
      host = "0.0.0.0";
      port = 11434;
      openFirewall = true;
      models = "/mnt/data/Ollama/models";
      environmentVariables = {
        OLLAMA_FLASH_ATTENTION = "True";
        HF_ENDPOINT = "https://hf-mirror.com";
      };
    };
    open-webui = {
      enable = true;
      host = "0.0.0.0";
      port = 11435;
      openFirewall = true;
      environment = {
        ANONYMIZED_TELEMETRY = "False";
        DO_NOT_TRACK = "True";
        SCARF_NO_ANALYTICS = "True";
        WEBUI_URL = "http://hakase.siki.moe:11435";
        ENABLE_SIGNUP = "False";
        ENABLE_OLLAMA_API = "True";
        OLLAMA_API_URLS = "http://127.0.0.1:11434";
        ENABLE_OPENAI_API = "False";
        HF_ENDPOINT = "https://hf-mirror.com";
      };
    };
  };
}
