# 简历项目描述建议

## 项目名称

**Non-blocking L2 Cache UVM Verification｜SystemVerilog / UVM**

## 简历三条版

- 基于开源 Vortex Cache RTL 搭建独立 UVM 验证环境，将 DUT 配置为 **256KB、4-way、64B Cache Line、4 Bank、Write Back + Write Allocate、每 Bank 8-entry MSHR**；完成双 Core Agent、反应式 Memory Agent/Memory Model、Scoreboard、SVA 与功能覆盖率模型。
- 围绕 Non-blocking Cache 并发控制设计定向/随机场景，覆盖 **Bank-local MSHR Full、32-entry Aggregate Outstanding、Same-line Pending、Out-of-order Refill、Clean/Dirty Eviction、Writeback/Refill Overlap、Flush、Core/Memory Backpressure、Partial Write** 等场景；Scoreboard 按 `{port, tag}` 跟踪 Read Response，并逐字节检查 Dirty Writeback。
- 建立 GitHub Actions + Verilator/UVM 自动回归与 scoped coverage 流程，并通过 mutation test 复现开源项目历史 Cache 控制缺陷，验证测试环境能够捕获 Flush pipeline race 与 MSHR release/coalesce race；最终回归/覆盖率数字以仓库 `docs/Regression_Report.md` 的真实 CI 结果为准。

## 面试时的真实性边界

RTL 是 Vortex 开源 RTL，不说成个人设计；个人贡献重点是：

**DUT 理解与裁剪 + vPlan + UVM TB + Memory Model + Scoreboard + Coverage + SVA + testcase + regression + debug/closure。**

Mutation test 是对 upstream 已修复历史 bug 的“重新注入并验证能够抓住”，不要说成自己最早发现并修复了 Vortex bug。

## 不建议写的表述

不要写：

- “独立设计 256KB L2 Cache RTL”
- “发现并修复 Vortex 两个官方 bug”
- “VCS/Verdi 回归全部通过”——在真正获得 VCS license 并跑过以前不能这么写。

可以写：

- “基于开源 RTL 独立搭建 UVM 验证平台”
- “复现并通过 mutation test 检出 upstream 历史 Cache bug”
- “Verilator/UVM CI 回归通过；VCS/Verdi flow 已提供脚本并预留”
