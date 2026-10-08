# 简历与面试项目口径（中文）

> 本文只使用已经在 GitHub Actions 实测过的结果。不要把历史 mutation case 说成自己原创发现的 RTL bug。

## 简历项目名称

**基于 Vortex 开源 RTL 的 Non-blocking L2 Cache UVM 验证**

## 简历精简版（3 条）

- 基于开源 Vortex Cache RTL 搭建独立 SystemVerilog/UVM 验证环境，配置 256KB、4-way、64B Cache Line、4 Bank、2 个上游请求端口、每 Bank 8-entry MSHR 的 Write-back / Write-allocate L2 Cache；完成 Core Agent、Memory Agent、Reference/Scoreboard、SVA、Functional Coverage 与自动回归框架。
- 针对 Read/Write Hit/Miss、Dirty/Clean Eviction、PLRU Replacement、Same-line Pending、8-entry 单 Bank MSHR Full、32-entry 全局并发、Out-of-order Refill、Memory/Core Backpressure、Flush 等场景设计 29 类定向/压力用例，并进行 5 组额外随机 Seed 回归；绿色基线 34 次正常仿真均为 0 UVM_ERROR / 0 UVM_FATAL。
- 新增 Memory-side 完整 Refill 数据校验：维护独立的 DRAM Reference Mirror，按 Memory Tag 保存和检查 512-bit 返回数据；正常回归校验 891 次完整 Refill，0 mismatch。设计单 Bit 数据破坏负向测试，即使 Core 写操作掩盖了错误、读回正确，也能由 `SB_MEM_DATA` 独立检出。
- 额外闭环 Refill Tag 生命周期与运行中 Reset 恢复：拦截 active tag 重用/未知或重复响应，实测 MSHR 释放后的合法 Tag reuse；在 4 个 Miss 未完成时 Reset，清理旧事务后验证 4 笔新读请求；同时验证 16 组双端口同字节互补写入在四个 Bank 上的逐字节读回。
- GitHub Actions 实测：Reachable Functional Coverage 100%（55/55），Cache RTL Scoped Coverage 为 Line 94.6%、Branch 84.7%、Expression 84.4%；通过 mutation verification 重新注入 Vortex 两个已公开历史缺陷，使用 white-box SVA 分别捕获 Flush/Bank-pipeline race 与 MSHR release/coalesce lifetime hazard。

## 简历稍短版（适合版面不足）

**L2 Cache UVM Verification**：基于 Vortex 开源 Cache RTL，自建 UVM 环境验证 256KB 4-way/4-bank Non-blocking L2，覆盖 8-entry MSHR/Bank、32 aggregate outstanding、Same-line Pending、OOO Refill、Dirty Eviction、PLRU、Backpressure 与 Flush。完成 29 类定向/压力测试 + 多 Seed 随机回归，Reachable Functional Coverage 55/55，Cache RTL Line/Branch Coverage 94.6%/84.7%；通过 SVA mutation check 捕获两个公开历史 Cache 控制类缺陷。

## 60 秒项目介绍

这个项目我选的是 Vortex 的开源 Cache RTL，主要想把验证重点放在真正的 Non-blocking Cache 并发控制上，而不是做一个简单的单 FSM Cache。DUT 配成 256KB、4-way、64B Cache Line、4 个 Bank，每个 Bank 8 个 MSHR，上游两个请求端口，采用 Write-back、Write-allocate 和 PLRU。

验证环境是我自己重新搭的，包含两个 Core Agent 和一个 reactive Memory Agent。Memory Model 可以随机做 request backpressure、不同 read latency 和 tagged out-of-order refill。Scoreboard 维护 byte-addressed architectural memory，通过 port+tag 对 Core response 做匹配，同时对 dirty writeback 的地址、byte enable 和 payload 做逐字节检查。

重点场景包括同一 Cache Line 的 pending request、单 Bank 8 个 MSHR 打满后第 9 笔 backpressure、4 Bank 共 32 个 outstanding miss、乱序 refill、dirty eviction、PLRU replacement、refill/writeback overlap 和 flush。现在 GitHub Actions 的正常回归是 29 类 testcase 加 5 个额外随机 seed，34 次正常仿真全部 0 UVM_ERROR/FATAL，reachable functional coverage 55/55，cache RTL line coverage 94.6%。

在并发资源管理上，我还补了一个 Memory Refill Tag Outstanding Table，检查 active Tag 是否被提前复用、响应是否重复或未知，以及最后有没有资源泄漏。Reset 测试会在 4 个 Miss 还没回填时复位，确认新一轮请求能干净恢复。另外还有 16 组跨 Core Port 的同字部分写入，两个 Port 更新不同字节，最后完整读回。

另外我还做了 mutation verification，把 Vortex 上游公开修过的两个历史 bug 临时重新注入，分别用 SVA 抓到了 flush 没等 bank pipeline 排空、以及 MSHR 在 release 同周期错误 coalesce 的问题，用来证明环境对这类控制 bug 确实有检测能力。

## 面试关键数字

- Cache：256 KiB
- Associativity：4-way
- Cache Line：64 B
- Banks：4
- Upstream request ports：2
- Word：64 bit
- MSHR：8 entries / bank
- Aggregate MSHR capacity：32
- Write policy：Write-back + Write-allocate
- Replacement：Pseudo-LRU
- 正常回归：29 类 functional/stress testcase + 5 个额外 random seeds
- Memory Tag 生命周期：复用 8 次，0 active-tag alias
- Reset：中止 4 笔读请求 / 4 笔 Refill，恢复后完成 4 笔新读
- 双端口同字部分写：16 组，四个 Bank 全覆盖
- 正常仿真总数：32
- Core-read scoreboard checks：1,254
- Refill requests：895
- Dirty writebacks：14
- Flush completions：2
- UVM_ERROR/FATAL：0 / 0
- Reachable functional coverage：55 / 55 = 100%
- Cache RTL line / branch / expression：94.6% / 84.7% / 84.4%

## 必须保持的表述边界

1. RTL 不是自己写的，来自开源 Vortex；自己的工作是 wrapper/configuration + verification。
2. 两个 mutation bug 是 **Vortex 已公开修复过的历史缺陷**，不能说成自己首次发现。
3. 当前实测覆盖率来自 **Verilator/UVM CI**；VCS/URG 脚本已经准备，但不要说已经跑过 VCS coverage，除非之后真的在有 license 的机器上执行。
4. 8-entry MSHR 是 **每个 Bank 8 个**；4 Bank 聚合最大容量为 32，不要说成全局只有 8 个。
