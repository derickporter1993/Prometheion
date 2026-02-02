import { Command } from "commander";
import chalk from "chalk";
import ora from "ora";
import { execSync } from "child_process";

interface TestOptions {
  targetOrg?: string;
  apex?: boolean;
  lwc?: boolean;
  all?: boolean;
  coverage?: boolean;
  json?: boolean;
  classNames?: string;
}

interface TestResult {
  type: "apex" | "lwc";
  passed: number;
  failed: number;
  skipped: number;
  coverage?: number;
  duration: number;
  failures: Array<{
    name: string;
    message: string;
  }>;
}

async function runApexTests(
  targetOrg?: string,
  classNames?: string,
  coverage?: boolean
): Promise<TestResult> {
  const orgFlag = targetOrg ? `--target-org ${targetOrg}` : "";
  const coverageFlag = coverage ? "--code-coverage" : "";
  const classFlag = classNames ? `--class-names ${classNames}` : "";

  const startTime = Date.now();
  let result: TestResult = {
    type: "apex",
    passed: 0,
    failed: 0,
    skipped: 0,
    duration: 0,
    failures: [],
  };

  try {
    const command = `sf apex run test ${orgFlag} ${classFlag} ${coverageFlag} --result-format json --wait 10`;
    const output = execSync(command, {
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
    });

    const data = JSON.parse(output);
    result = {
      type: "apex",
      passed: data.result?.summary?.passing || 0,
      failed: data.result?.summary?.failing || 0,
      skipped: data.result?.summary?.skipped || 0,
      coverage: data.result?.summary?.orgWideCoverage
        ? parseFloat(data.result.summary.orgWideCoverage)
        : undefined,
      duration: Date.now() - startTime,
      failures:
        data.result?.tests
          ?.filter((t: { Outcome: string }) => t.Outcome === "Fail")
          .map((t: { FullName: string; Message: string }) => ({
            name: t.FullName,
            message: t.Message,
          })) || [],
    };
  } catch (execError) {
    const errorOutput = (execError as { stdout?: string }).stdout || "";
    try {
      const data = JSON.parse(errorOutput);
      result = {
        type: "apex",
        passed: data.result?.summary?.passing || 0,
        failed: data.result?.summary?.failing || 0,
        skipped: 0,
        duration: Date.now() - startTime,
        failures:
          data.result?.tests
            ?.filter((t: { Outcome: string }) => t.Outcome === "Fail")
            .map((t: { FullName: string; Message: string }) => ({
              name: t.FullName,
              message: t.Message,
            })) || [],
      };
    } catch {
      result.failures = [{ name: "Apex Tests", message: "Failed to run tests" }];
    }
  }

  return result;
}

async function runLwcTests(coverage?: boolean): Promise<TestResult> {
  const startTime = Date.now();
  let result: TestResult = {
    type: "lwc",
    passed: 0,
    failed: 0,
    skipped: 0,
    duration: 0,
    failures: [],
  };

  try {
    const coverageFlag = coverage ? "--coverage" : "";
    const command = `npm run test:unit ${coverageFlag} --json 2>/dev/null || true`;
    const output = execSync(command, {
      encoding: "utf-8",
      stdio: ["pipe", "pipe", "pipe"],
      cwd: process.cwd(),
    });

    // Parse Jest JSON output
    try {
      const lines = output.split("\n");
      const jsonLine = lines.find((l) => l.startsWith("{"));
      if (jsonLine) {
        const data = JSON.parse(jsonLine);
        result = {
          type: "lwc",
          passed: data.numPassedTests || 0,
          failed: data.numFailedTests || 0,
          skipped: data.numPendingTests || 0,
          duration: Date.now() - startTime,
          failures:
            data.testResults
              ?.flatMap((tr: { assertionResults: Array<{ status: string; title: string; failureMessages: string[] }> }) =>
                tr.assertionResults
                  .filter((ar) => ar.status === "failed")
                  .map((ar) => ({
                    name: ar.title,
                    message: ar.failureMessages?.[0] || "Test failed",
                  }))
              ) || [],
        };
      }
    } catch {
      // Fallback to basic parsing
      const passMatch = output.match(/(\d+) passing/);
      const failMatch = output.match(/(\d+) failing/);
      result.passed = passMatch ? parseInt(passMatch[1] ?? "0", 10) : 0;
      result.failed = failMatch ? parseInt(failMatch[1] ?? "0", 10) : 0;
      result.duration = Date.now() - startTime;
    }
  } catch {
    result.failures = [{ name: "LWC Tests", message: "Failed to run tests" }];
  }

  return result;
}

function displayTestResult(result: TestResult): void {
  const typeLabel = result.type === "apex" ? "Apex Tests" : "LWC Tests";
  const total = result.passed + result.failed + result.skipped;
  const statusColor = result.failed > 0 ? chalk.red : chalk.green;

  console.log();
  console.log(chalk.bold(typeLabel));
  console.log(chalk.gray("─".repeat(40)));
  console.log(`  Total:    ${total}`);
  console.log(`  Passed:   ${chalk.green(result.passed.toString())}`);
  console.log(`  Failed:   ${chalk.red(result.failed.toString())}`);
  if (result.skipped > 0) {
    console.log(`  Skipped:  ${chalk.yellow(result.skipped.toString())}`);
  }
  console.log(`  Duration: ${(result.duration / 1000).toFixed(2)}s`);

  if (result.coverage !== undefined) {
    const coverageColor =
      result.coverage >= 75
        ? chalk.green
        : result.coverage >= 50
          ? chalk.yellow
          : chalk.red;
    console.log(`  Coverage: ${coverageColor(result.coverage + "%")}`);
  }

  if (result.failures.length > 0) {
    console.log();
    console.log(chalk.red("  Failures:"));
    result.failures.slice(0, 5).forEach((failure) => {
      console.log(`    ${chalk.red("✗")} ${failure.name}`);
      console.log(chalk.gray(`      ${failure.message.substring(0, 100)}`));
    });
    if (result.failures.length > 5) {
      console.log(
        chalk.gray(`    ... and ${result.failures.length - 5} more failures`)
      );
    }
  }
}

async function runTests(options: TestOptions): Promise<void> {
  const spinner = ora("Running tests...").start();

  try {
    const results: TestResult[] = [];

    // Determine which tests to run
    const runApex = options.apex || options.all || (!options.apex && !options.lwc);
    const runLwc = options.lwc || options.all;

    if (runApex) {
      spinner.text = "Running Apex tests...";
      const apexResult = await runApexTests(
        options.targetOrg,
        options.classNames,
        options.coverage
      );
      results.push(apexResult);
    }

    if (runLwc) {
      spinner.text = "Running LWC tests...";
      const lwcResult = await runLwcTests(options.coverage);
      results.push(lwcResult);
    }

    spinner.stop();

    if (options.json) {
      console.log(JSON.stringify(results, null, 2));
      return;
    }

    console.log();
    console.log(chalk.bold.cyan("Elaro Test Results"));
    console.log(chalk.gray("═".repeat(50)));

    for (const result of results) {
      displayTestResult(result);
    }

    // Summary
    const totalPassed = results.reduce((sum, r) => sum + r.passed, 0);
    const totalFailed = results.reduce((sum, r) => sum + r.failed, 0);
    const totalDuration = results.reduce((sum, r) => sum + r.duration, 0);

    console.log();
    console.log(chalk.gray("─".repeat(50)));
    console.log(chalk.bold("Summary:"));
    console.log(`  Total Passed: ${chalk.green(totalPassed.toString())}`);
    console.log(`  Total Failed: ${chalk.red(totalFailed.toString())}`);
    console.log(`  Total Time:   ${(totalDuration / 1000).toFixed(2)}s`);
    console.log();

    if (totalFailed > 0) {
      console.log(chalk.red("Some tests failed. Fix the issues and run again."));
      process.exit(1);
    } else {
      console.log(chalk.green("All tests passed!"));
    }
  } catch (error) {
    spinner.fail("Tests failed");
    if (error instanceof Error) {
      console.error(chalk.red(error.message));
    }
    process.exit(1);
  }
}

export const testCommand = new Command("test")
  .description("Run Elaro tests")
  .option("-o, --target-org <alias>", "Target Salesforce org alias (for Apex tests)")
  .option("-a, --apex", "Run Apex tests only")
  .option("-l, --lwc", "Run LWC tests only")
  .option("--all", "Run all tests (Apex and LWC)")
  .option("-c, --coverage", "Include code coverage in results")
  .option("-n, --class-names <names>", "Comma-separated list of Apex test classes")
  .option("--json", "Output results in JSON format")
  .action(runTests);
