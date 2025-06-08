# process Manager

## 核心结构体

```go
type Manager struct {
	procs          map[string]*Process
	eventListeners map[string]*Process
	lock           sync.Mutex
}
// Process the program process management data
type Process struct {
	supervisorID string
	config       *config.Entry
	cmd          *exec.Cmd
	startTime    time.Time
	stopTime     time.Time
	state        State
	//true if process is starting
	inStart bool
	//true if the process is stopped by user
	stopByUser bool
	retryTimes *int32
	lock       sync.RWMutex
	stdin      io.WriteCloser
	StdoutLog  logger.Logger
	StderrLog  logger.Logger
}


```

## 核心方法

![image-20250608091915787](C:\Users\86186\AppData\Roaming\Typora\typora-user-images\image-20250608091915787.png)

### 启动进程

#### CreateProcess

![image-20250608092211754](C:\Users\86186\AppData\Roaming\Typora\typora-user-images\image-20250608092211754.png)

![image-20250608092236194](C:\Users\86186\AppData\Roaming\Typora\typora-user-images\image-20250608092236194.png)

![image-20250608092320125](C:\Users\86186\AppData\Roaming\Typora\typora-user-images\image-20250608092320125.png)

![image-20250608092144732](C:\Users\86186\AppData\Roaming\Typora\typora-user-images\image-20250608092144732.png)

![image-20250608093646950](C:\Users\86186\AppData\Roaming\Typora\typora-user-images\image-20250608093646950.png)

如果配置中有cron表达式，则根据表达式启动进程，否则此时cron表达式会返错，不会启动进程。

#### Start

每调用一次start就启动一个goroutine，每个goroutine中有俩层循环：

* **外层控制启停流程的执行**
* **内层控制进程真正的启停，状态监控，重启等控制**

![image-20250608094459304](C:\Users\86186\AppData\Roaming\Typora\typora-user-images\image-20250608094459304.png)

循环什么时候退出？

* 一种是被用户停止，即stopByUser被设置
* 另一种是没有设置自动重启，即isAutoRestart为false的情况

p.run中负责启动进程，启动时会加锁并设置p.startTime

```go
func (p *Process) run(finishCb func()) {
	p.lock.Lock()
	defer p.lock.Unlock()

	// check if the program is in running state
	if p.isRunning() {   // 这里会判断进程是否运行
		log.WithFields(log.Fields{"program": p.GetName()}).Info("Don't start program because it is running")
		finishCb()
		return
	}
	p.startTime = time.Now() // 这里设置时间，run外面的循环会循环执行，执行时，如果发现状态是running, 则return，外层循环会判断启动时间和当前时间的是否小于2秒，小于则等5秒
    ...
	var once sync.Once
    ...
	//process is not expired and not stoped by user
	for !p.stopByUser {
         ...
		err := p.createProgramCommand()
		err = p.cmd.Start()
         ...
		log.WithFields(log.Fields{"program": p.GetName()}).Debug("wait program exit")
		p.lock.Unlock()
		p.waitForExit(startSecs)  // 在这里进行wait, 会阻塞
         atomic.StoreInt32(&programExited, 1) // 通过这个有monitor检测是否运行
		...
         p.lock.Lock()
         ...
	}
}
```

![image-20250608203216168](C:\Users\86186\AppData\Roaming\Typora\typora-user-images\image-20250608203216168.png)

![image-20250608204314484](C:\Users\86186\AppData\Roaming\Typora\typora-user-images\image-20250608204314484.png)

