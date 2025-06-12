**proc.c**: 这个示例展示了如何获取进程的基本信息：除了使用 API (例如 getpid 是一个系统调用)，Linux `/proc` 文件系统允许我们使用文件 API (“everything is a file”) 访问当前进程的 ID、状态信息、命令行参数和工作目录等元数据。
