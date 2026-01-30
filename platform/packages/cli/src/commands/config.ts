import { Command } from "commander";
import chalk from "chalk";
import { existsSync, readFileSync, writeFileSync, mkdirSync } from "fs";
import { homedir } from "os";
import { join } from "path";

interface ElaroConfig {
  defaultOrg?: string;
  defaultFrameworks?: string[];
  outputFormat?: "text" | "json";
  colors?: boolean;
  notifications?: {
    slack?: string;
    email?: string;
  };
}

const CONFIG_DIR = join(homedir(), ".elaro");
const CONFIG_FILE = join(CONFIG_DIR, "config.json");

function ensureConfigDir(): void {
  if (!existsSync(CONFIG_DIR)) {
    mkdirSync(CONFIG_DIR, { recursive: true });
  }
}

function loadConfig(): ElaroConfig {
  ensureConfigDir();
  if (existsSync(CONFIG_FILE)) {
    try {
      const content = readFileSync(CONFIG_FILE, "utf-8");
      return JSON.parse(content);
    } catch {
      return {};
    }
  }
  return {};
}

function saveConfig(config: ElaroConfig): void {
  ensureConfigDir();
  writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
}

async function showConfig(options: { json?: boolean }): Promise<void> {
  const config = loadConfig();

  if (options.json) {
    console.log(JSON.stringify(config, null, 2));
    return;
  }

  console.log();
  console.log(chalk.bold.cyan("Elaro Configuration"));
  console.log(chalk.gray("─".repeat(50)));
  console.log();
  console.log(chalk.gray(`Config file: ${CONFIG_FILE}`));
  console.log();

  if (Object.keys(config).length === 0) {
    console.log(chalk.yellow("  No configuration set"));
    console.log(chalk.gray("  Run 'elaro config set <key> <value>' to configure"));
  } else {
    console.log(chalk.bold("Current Settings:"));
    console.log(`  Default Org:        ${config.defaultOrg || chalk.gray("(not set)")}`);
    console.log(
      `  Default Frameworks: ${config.defaultFrameworks?.join(", ") || chalk.gray("(not set)")}`
    );
    console.log(`  Output Format:      ${config.outputFormat || chalk.gray("text")}`);
    console.log(`  Colors:             ${config.colors !== false ? chalk.green("enabled") : chalk.red("disabled")}`);

    if (config.notifications) {
      console.log();
      console.log(chalk.bold("Notifications:"));
      console.log(`  Slack:  ${config.notifications.slack || chalk.gray("(not set)")}`);
      console.log(`  Email:  ${config.notifications.email || chalk.gray("(not set)")}`);
    }
  }

  console.log();
  console.log(chalk.bold("Available Settings:"));
  console.log(chalk.gray("  defaultOrg        - Default Salesforce org alias"));
  console.log(chalk.gray("  defaultFrameworks - Comma-separated compliance frameworks"));
  console.log(chalk.gray("  outputFormat      - Output format (text or json)"));
  console.log(chalk.gray("  colors            - Enable/disable colors (true/false)"));
  console.log(chalk.gray("  slack             - Slack webhook URL for notifications"));
  console.log(chalk.gray("  email             - Email for compliance reports"));
  console.log();
}

async function setConfig(key: string, value: string): Promise<void> {
  const config = loadConfig();

  switch (key) {
    case "defaultOrg":
      config.defaultOrg = value;
      break;
    case "defaultFrameworks":
      config.defaultFrameworks = value.split(",").map((f) => f.trim().toLowerCase());
      break;
    case "outputFormat":
      if (value !== "text" && value !== "json") {
        console.error(chalk.red("Error: outputFormat must be 'text' or 'json'"));
        process.exit(1);
      }
      config.outputFormat = value;
      break;
    case "colors":
      config.colors = value.toLowerCase() === "true";
      break;
    case "slack":
      if (!config.notifications) config.notifications = {};
      config.notifications.slack = value;
      break;
    case "email":
      if (!config.notifications) config.notifications = {};
      config.notifications.email = value;
      break;
    default:
      console.error(chalk.red(`Error: Unknown config key '${key}'`));
      console.log(chalk.gray("Run 'elaro config' to see available settings"));
      process.exit(1);
  }

  saveConfig(config);
  console.log(chalk.green(`Set ${key} = ${value}`));
}

async function unsetConfig(key: string): Promise<void> {
  const config = loadConfig();

  switch (key) {
    case "defaultOrg":
      delete config.defaultOrg;
      break;
    case "defaultFrameworks":
      delete config.defaultFrameworks;
      break;
    case "outputFormat":
      delete config.outputFormat;
      break;
    case "colors":
      delete config.colors;
      break;
    case "slack":
      if (config.notifications) delete config.notifications.slack;
      break;
    case "email":
      if (config.notifications) delete config.notifications.email;
      break;
    default:
      console.error(chalk.red(`Error: Unknown config key '${key}'`));
      process.exit(1);
  }

  saveConfig(config);
  console.log(chalk.green(`Unset ${key}`));
}

async function resetConfig(): Promise<void> {
  saveConfig({});
  console.log(chalk.green("Configuration reset to defaults"));
}

export const configCommand = new Command("config")
  .description("Manage Elaro CLI configuration")
  .option("--json", "Output in JSON format")
  .action(showConfig)
  .addCommand(
    new Command("set")
      .description("Set a configuration value")
      .argument("<key>", "Configuration key")
      .argument("<value>", "Configuration value")
      .action(setConfig)
  )
  .addCommand(
    new Command("unset")
      .description("Remove a configuration value")
      .argument("<key>", "Configuration key")
      .action(unsetConfig)
  )
  .addCommand(
    new Command("reset")
      .description("Reset configuration to defaults")
      .action(resetConfig)
  );
