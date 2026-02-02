import { Command } from "commander";
import chalk from "chalk";
import ora from "ora";
import { execSync } from "child_process";

interface DeployOptions {
  targetOrg?: string;
  validate?: boolean;
  testLevel?: string;
  json?: boolean;
  watch?: boolean;
}

interface DeployResult {
  success: boolean;
  componentsDeployed: number;
  componentsFailed: number;
  testsPassed?: number;
  testsFailed?: number;
  coverage?: number;
  errors: string[];
  warnings: string[];
}

async function runDeploy(options: DeployOptions): Promise<void> {
  const spinner = ora(
    options.validate ? "Validating deployment..." : "Deploying to Salesforce..."
  ).start();

  try {
    const orgFlag = options.targetOrg ? `--target-org ${options.targetOrg}` : "";
    const validateFlag = options.validate ? "--dry-run" : "";
    const testLevelFlag = options.testLevel
      ? `--test-level ${options.testLevel}`
      : "";
    const waitFlag = options.watch ? "--wait 30" : "--wait 10";

    const command = `sf project deploy start ${orgFlag} ${validateFlag} ${testLevelFlag} ${waitFlag} --json`;

    spinner.text = options.validate
      ? "Running validation deployment..."
      : "Deploying metadata to org...";

    let result: DeployResult;

    try {
      const output = execSync(command, {
        encoding: "utf-8",
        stdio: ["pipe", "pipe", "pipe"],
        cwd: process.cwd(),
      });

      const data = JSON.parse(output);
      result = {
        success: data.status === 0,
        componentsDeployed: data.result?.numberComponentsDeployed || 0,
        componentsFailed: data.result?.numberComponentErrors || 0,
        testsPassed: data.result?.numberTestsCompleted,
        testsFailed: data.result?.numberTestErrors,
        coverage: data.result?.coverage,
        errors: data.result?.details?.componentFailures?.map(
          (f: { problem: string }) => f.problem
        ) || [],
        warnings: data.warnings || [],
      };
    } catch (execError) {
      // Try to parse error output
      const errorOutput = (execError as { stdout?: string }).stdout || "";
      try {
        const data = JSON.parse(errorOutput);
        result = {
          success: false,
          componentsDeployed: data.result?.numberComponentsDeployed || 0,
          componentsFailed: data.result?.numberComponentErrors || 0,
          errors: data.result?.details?.componentFailures?.map(
            (f: { problem: string }) => f.problem
          ) || [data.message || "Deployment failed"],
          warnings: [],
        };
      } catch {
        result = {
          success: false,
          componentsDeployed: 0,
          componentsFailed: 0,
          errors: ["Deployment failed - check Salesforce CLI installation"],
          warnings: [],
        };
      }
    }

    spinner.stop();

    if (options.json) {
      console.log(JSON.stringify(result, null, 2));
      return;
    }

    console.log();
    console.log(
      chalk.bold.cyan(
        options.validate ? "Deployment Validation Results" : "Deployment Results"
      )
    );
    console.log(chalk.gray("─".repeat(50)));
    console.log();

    if (result.success) {
      console.log(
        chalk.green.bold(
          options.validate
            ? "Validation Successful"
            : "Deployment Successful"
        )
      );
    } else {
      console.log(chalk.red.bold("Deployment Failed"));
    }

    console.log();
    console.log(chalk.bold("Summary:"));
    console.log(
      `  Components Deployed: ${chalk.green(result.componentsDeployed.toString())}`
    );
    if (result.componentsFailed > 0) {
      console.log(
        `  Components Failed:   ${chalk.red(result.componentsFailed.toString())}`
      );
    }

    if (result.testsPassed !== undefined) {
      console.log();
      console.log(chalk.bold("Test Results:"));
      console.log(`  Tests Passed: ${chalk.green(result.testsPassed.toString())}`);
      if (result.testsFailed !== undefined && result.testsFailed > 0) {
        console.log(`  Tests Failed: ${chalk.red(result.testsFailed.toString())}`);
      }
      if (result.coverage !== undefined) {
        const coverageColor =
          result.coverage >= 75
            ? chalk.green
            : result.coverage >= 50
              ? chalk.yellow
              : chalk.red;
        console.log(`  Coverage:     ${coverageColor(result.coverage + "%")}`);
      }
    }

    if (result.errors.length > 0) {
      console.log();
      console.log(chalk.red.bold("Errors:"));
      result.errors.slice(0, 10).forEach((error) => {
        console.log(`  ${chalk.red("✗")} ${error}`);
      });
      if (result.errors.length > 10) {
        console.log(chalk.gray(`  ... and ${result.errors.length - 10} more errors`));
      }
    }

    if (result.warnings.length > 0) {
      console.log();
      console.log(chalk.yellow.bold("Warnings:"));
      result.warnings.forEach((warning) => {
        console.log(`  ${chalk.yellow("!")} ${warning}`);
      });
    }

    console.log();

    if (!result.success) {
      process.exit(1);
    }
  } catch (error) {
    spinner.fail("Deployment failed");
    if (error instanceof Error) {
      console.error(chalk.red(error.message));
    }
    process.exit(1);
  }
}

export const deployCommand = new Command("deploy")
  .description("Deploy Elaro to Salesforce org")
  .option("-o, --target-org <alias>", "Target Salesforce org alias")
  .option("-v, --validate", "Validate deployment without making changes (dry-run)")
  .option(
    "-l, --test-level <level>",
    "Test level (NoTestRun, RunSpecifiedTests, RunLocalTests, RunAllTestsInOrg)"
  )
  .option("-w, --watch", "Wait for deployment to complete (extended timeout)")
  .option("--json", "Output results in JSON format")
  .action(runDeploy);
