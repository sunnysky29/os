#import "../template.typ": *
#pagebreak()
= Scheduling

== Scheduling: Introduction

We have yet to understand the high-level policies that an OS scheduler employs. We will now present a series of *scheduling policies* (sometimes called *disciplines*)

=== Workload Assumptions

The more you know about *workload*, the more fine-tuned your policy can be.

The workload assumptions we make here are mostly unrealistic, but that is alright, because we will relax them as we go, and eventually develop what we will refer to as *a fully-operational scheduling discipline*

We will make the following assumptions about the processes, sometimes called *jobs*, that are running in the system:

1. Each job runs for the same amount of time.
2. All jobs arrive at the same time.
3. Once started, each job runs to completion.
4. All jobs only use the CPU (i.e., they perform no I/O)
5. The run-time of each job is known.

=== Scheduling Metrics: turnaround time

The turnaround time of a job is defined as the time at which the job completes minus the time at which the job arrived in the system.
$T_"turnaround" = T_"completion" − T_"arrival"$

Because we have assumed that all jobs arrive at the same time, for now $T_"arrival" = 0$ and hence $T_"turnaround" = T_"completion"$.

Turnaround time is a *performance* metric.
Another metric of interest is *fairness*.

Performance and fairness are often at odds in scheduling; a scheduler, for example, may optimize performance but at the cost of preventing a few jobs from running, thus decreasing fairness.

=== First In, First Out (FIFO)

The most basic algorithm we can implement is known as *First In, First Out (FIFO)* scheduling or sometimes *First Come, First Served (FCFS)*.

Positive properties:

- it is clearly simple and thus easy to implement
- given our assumptions, it works pretty well

Imagine three jobs arrive in the system, A, B, and C, at roughly the same time ($T_"arrival" = 0$).

Because FIFO has to put some job first, let's assume that while they all arrived simultaneously, A arrived just a hair before B which arrived just a hair before C.

Assume also that each job runs for 10 seconds.

#image("images/2023-12-18-21-14-55.png", width: 70%)

The average turnaround time for the three jobs is (10+20+30)/3 = 20.

Let's relax assumption 1, and thus no longer assume that each job runs for the same amount of time. What kind of workload could you construct to make FIFO perform poorly?

Assume three jobs (A, B, and C), but this time A runs for 100 seconds while B and C run for 10 each.

#image("images/2023-12-18-21-17-01.png", width:70%)

The average turnaround time for the system is high: (100+110+120)/3 = 110.

This problem is generally referred to as the *convoy effect* where a number of relatively-short potential consumers of a resource get queued behind a heavyweight resource consumer.

=== Shortest Job First (SJF)

To solve the above problem, a new scheduling discipline known as *Shortest Job First (SJF)* occurred. It runs the shortest job first, then the next shortest, and so on.

#image("images/2023-12-18-21-20-12.png", width:70%)

The average turnaround time for the system is (10+20+120)/3 = 50.(reduce 110 to 50)

We can target assumption 2, and now assume that jobs can arrive at any time instead of all at once. What problems does this lead to?

Assume A arrives at t = 0 and needs to run for 100 seconds, whereas B and C arrive at t = 10 and each need to run for 10 seconds.

#image("images/2023-12-18-21-22-13.png", width:70%)

Average turnaround time for these three jobs is (100+(110−10)+(120−10))/3 = 103.33 seconds.

=== Shortest Time-to-Completion First (STCF)

==== PREEMPTIVE SCHEDULERS

A number of *non-preemptive* schedulers were developed; such systems would run each job to completion before considering whether to run a new job.
All modern schedulers are *preemptive*, and quite willing to stop one process from running in order to run another.

==== STCF

- We need to relax assumption 3 (that jobs must run to completion).
- We also need some machinery within the scheduler itself.(timer interrupts and context switching)

The scheduler can certainly do something else when B and C arrive: it can *preempt* job A and decide to run another job, perhaps continuing A later.

There is a scheduler which does exactly that: add preemption to SJF, known as the Shortest *Time-to-Completion First (STCF)* or *Preemptive Shortest Job First (PSJF)* scheduler.

#image("images/2023-12-18-21-25-48.png", width:70%)

The result is a much-improved average turnaround time: ((120−0)+(20−10)+(30−10))/3 = 50 seconds

=== A New Metric: Response Time

Users would sit at a terminal and demand *interactive* performance from the system as well. New metric was born: *response time*.

We define response time as the time from when the job arrives in a system to the first time it is scheduled.
$T_"response" = T_"firstrun" − T_"arrival"$

For example, if we had the schedule above (with A arriving at time 0, and B and C at time 10), the response time of each job is as follows: 0 for job A, 0 for B, and 10 for C (average: 3.33).

STCF and related disciplines are not particularly good for response time.

If three jobs arrive at the same time, for example, the third job has to wait for the previous two jobs to run in *their entirety* before being scheduled just once.

While great for turnaround time, this approach is quite bad for response time and interactivity.

=== Round Robin

A new scheduling algorithm, classically referred to as *Round-Robin (RR) scheduling*.
Instead of running jobs to completion, RR runs a job for a time slice (sometimes called a scheduling quantum) and then switches to the next job in the run queue. It repeatedly does so until the jobs are finished.

#tip("Tip")[
  - RR is sometimes called *time-slicing*
  - The length of a time slice must be a multiple of the timer-interrupt period
]

Assume three jobs A, B, and C arrive at the same time in the system, and that they each wish to run for 5 seconds.

- An SJF scheduler runs each job to completion before running another.
- RR with a time-slice of 1 second would cycle through the jobs quickly.

#image("images/2023-12-18-21-29-55.png", width: 70%)

- For SJF, the average response time is: (0+5+10)/3 = 5.
- The average response time of RR is: (0+1+2)/3 = 1;

Making the time slice too short is problematic: suddenly the cost of context switching will dominate overall performance.

Thus, deciding on the length of the time slice presents a trade-off to a system designer, making it long enough to amortize the cost of switching without making it so long that the system is no longer responsive.

#tip("Tip")[
    The general technique of *amortization* is commonly used in systems when there is a fixed cost to some operation.
]

Note that the cost of context switching does not arise solely from the OS actions of saving and restoring a few registers.

When programs run, they build up a great deal of state in CPU caches, TLBs, branch predictors, and other on-chip hardware.

Switching to another job causes this state to be flushed and new state relevant to the currently-running job to be brought in, which may exact a noticeable performance cost.

The turnaround time of RR: A finishes at 13, B at 14, and C at 15, for an average of 14. Pretty awful!

RR is indeed one of the worst policies if turnaround time is our metric. RR is doing is stretching out each job as long as it can, by only running each job for a short bit before moving to the next. Because turnaround time only cares about when jobs finish, RR is nearly pessimal.

Any policy (such as RR) that is fair, i.e., that evenly divides the CPU among active processes on a small time scale, will perform poorly on metrics such as turnaround time.

Indeed, this is an inherent trade-off:

- if you are willing to be unfair, you can run shorter jobs to completion, but at the cost of response time;
- if you instead value fairness, response time is lowered, but at the cost of turnaround time. This type of trade-off is common in systems.

We have developed two types of schedulers.

- The first type (SJF, STCF) optimizes turnaround time, but is bad for response time.
- The second type (RR) optimizes response time but is bad for turnaround.

And we still have two assumptions which need to be relaxed:

- assumption 4 (that jobs do no I/O)
- assumption 5 (that the run-time of each job is known).

=== Incorporating I/O

First we will relax assumption 4 — of course all programs perform I/O.

- Imagine a program that didn't take any input: it would produce the same output each time.
- Imagine one without output: it is the proverbial tree falling in the forest, with no one to see it; it doesn't matter that it ran.

- A scheduler clearly has a decision to make when a job initiates an I/O request, because the currently-running job won't be using the CPU during the I/O; it is blocked waiting for I/O completion.
  #tip("Tip")[
  the scheduler should probably schedule another job on the CPU at that time.
  ]
- A scheduler also has to make a decision when the I/O completes. When that occurs, an interrupt is raised, and the OS runs and moves the process that issued the I/O from blocked back to the ready state. Of course, it could even decide to run the job at that point.

Let us assume we have two jobs, A and B, which each need 50 ms of CPU time.

- A runs for 10 ms and then issues an I/O request (assume here that I/Os each take 10 ms)
- B simply uses the CPU for 50 ms and performs no I/O.

The scheduler runs A first, then B after:
#image("images/2023-12-18-21-40-56.png", width: 70%)

A common approach is to treat each 10-ms sub-job of A as an independent job.
Thus, when the system starts, its choice is whether to schedule a 10-ms A or a 50-ms B.
With STCF, the choice is clear: choose the shorter one, in this case A. Then, when the first sub-job of A has completed, only B is left, and it begins running. Then a new sub-job of A is submitted, and it preempts B and runs for 10 ms.

#tip("Tip")[
    Doing so allows for *overlap*, with the CPU being used by one process while waiting for the I/O of another process to complete; the system is thus better utilized
]

#image("images/2023-12-18-21-42-16.png", width:70%)

=== No More Oracle

With a basic approach to I/O in place, we come to our final assumption: that the scheduler knows the length of each job. As we said before, this is likely the worst assumption we could make.

See the next chapter....

== Scheduling: The Multi-Level Feedback Queue

The fundamental problem *MLFQ* tries to address is two-fold.

First, it would like to optimize *turnaround time*, which is done by running shorter jobs first; unfortunately, the OS doesn't generally know how long a job will run for.

Second, MLFQ would like to make a system feel responsive to interactive users (i.e., users sitting and staring at the screen, waiting for a process to finish), and thus minimize response time.

Our problem: given that we in general do not know anything about a process, how can we build a scheduler to achieve these goals?

The multi-level feedback queue is an excellent example of a system that *learns from the past to predict the future*. Such approaches are common in operating systems (and many other places in Computer Science, including *hardware branch predictors* and *caching algorithms*).

#tip("Tip")[
    One must be careful with such techniques, as they can easily be wrong and drive a system to make worse decisions than they would have with no knowledge at all.
]

=== MLFQ: Basic Rules

The MLFQ has a number of distinct *queues*, each assigned a different priority level.

At any given time, a job that is ready to run is on a single queue.

MLFQ uses priorities to decide which job should run at a given time: a job with higher priority (i.e., a job on a higher queue) is chosen to run.

More than one job may be on a given queue, and thus have the same priority. In this case, we will just use *round-robin scheduling* among those jobs.

Thus, we arrive at the first two basic rules for MLFQ:

- Rule 1: If Priority(A) > Priority(B), A runs (B doesn't).
- Rule 2: If Priority(A) = Priority(B), A & B run in RR.

==== sets priorities

The key to MLFQ scheduling therefore lies in how the scheduler sets priorities.

MLFQ varies the priority of a job based on its *observed behavior*:

- A job repeatedly relinquishes the CPU while waiting for input from the keyboard, MLFQ will keep its priority high, as this is how an interactive process might behave.
- A job uses the CPU intensively for long periods of time,MLFQ will reduce its priority.

In this way,MLFQ will try to learn about processes as they run, and thus use the history of the job to predict its future behavior.

#image("images/2023-12-19-07-30-12.png", width: 50%)

In the figure, two jobs (A and B) are at the highest priority level, while job C is in the middle and Job D is at the lowest priority.

Given our current knowledge of how MLFQ works, the scheduler would just alternate time slices between A and B because they are the highest priority jobs in the system; poor jobs C and D would never even get to run!

=== Attempt #1: How To Change Priority

To do this, we must keep in mind our workload: a mix of interactive jobs that are short-running (and may frequently relinquish the CPU), and some longer-running “CPU-bound” jobs that need a lot of CPU time but where response time isn't important.

Here is our first attempt at a priority adjustment algorithm:

- Rule 3: When a job enters the system, it is placed at the highest priority (the topmost queue).
- Rule 4a: If a job uses up an entire time slice while running, its priority is reduced (i.e., it moves down one queue).
- Rule 4b: If a job gives up the CPU before the time slice is up, it stays at the same priority level.

==== Example 1: A Single Long-Running Job

#image("images/2023-12-19-12-35-43.png", width: 50%)

- The job enters at the highest priority (Q2).
- After a single time-slice of 10 ms, the scheduler reduces the job's priority by one, and thus the job is on Q1.
- After running at Q1 for a time slice, the job is finally lowered to the lowest priority in the system (Q0), where it remains.

==== Example 2: Along Came A Short Job

See how MLFQ tries to approximate SJF.

- A, which is a long-running CPU-intensive job
- B,which is a short-running interactive job.
- Assume A has been running for some time, and then B arrives.

#image("images/2023-12-19-12-37-19.png", width: 50%)

- A (shown in black) is running along in the lowest-priority queue;
- B (shown in gray) arrives at time T = 100, and thus is inserted into the highest queue; as its run-time is short (only 20 ms), B completes before reaching the bottom queue, in two time slices;
- A resumes running (at low priority).

From this example, we can understand one of the major goals of the algorithm:
because it doesn't know whether a job will be a short job or a long-running job, it *first assumes it might be a short job*, thus giving the job high priority.

- If it actually is a short job, it will run quickly and complete;
- If it is not a short job, it will slowly move down the queues, and thus soon prove itself to be a long-running more batch-like process.

#tip("Tip")[
    In this manner, MLFQ approximates SJF.
]

==== Example 3: What About I/O?

As Rule 4b states above, if a process gives up the processor before using up its time slice, we keep it at the same priority level.

The intent of this rule is simple: if an interactive job, for example, is doing a lot of I/O (say by waiting for user input from the keyboard or mouse), it will relinquish the CPU before its time slice is complete; in such case, we don't wish to penalize the job and thus simply keep it at the same level.

#image("images/2023-12-19-12-41-54.png", width: 50%)

With an interactive job B (shown in gray) that needs the CPU only for 1 ms before performing an I/O competing for the CPU with a long-running batch job A (shown in black).

The MLFQ approach keeps B at the highest priority because B keeps releasing the CPU; if B is an interactive job,MLFQ further achieves its goal of running interactive jobs quickly.

==== Problems With Our Current MLFQ

===== starvation

If there are “too many” interactive jobs in the system, they will combine to consume all CPU time, and thus long-running jobs will never receive any CPU time (they starve).

===== game the scheduler

Gaming the scheduler generally refers to the idea of doing something sneaky to trick the scheduler into giving you more than your fair share of the resource.

The algorithm we have described is susceptible to the following attack:

- before the time slice is over, issue an I/O operation and thus relinquish the CPU;
- doing so allows you to remain in the same queue, and thus gain a higher percentage of CPU time.
- When done right (e.g., by running for 99%of a time slice before relinquishing the CPU), a job could nearly monopolize the CPU.

===== the program change its behavior

What was CPU-bound may transition to a phase of interactivity.

With our current approach, such a job would be out of luck and not be treated like the other interactive jobs in the system.

=== Attempt #2: The Priority Boost

The simple idea here is to periodically boost the priority of all the jobs in system. Just do something simple: throw them all in the topmost queue; hence, a new rule:

- Rule 5: After some time period S, move all the jobs in the system to the topmost queue.

Our new rule solves two problems at once.

- First, processes are guaranteed not to starve: By sitting in the top queue, a job will share the CPU with other high-priority jobs in a *round-robin* fashion, and thus eventually receive service.
- Second, if a CPU-bound job has become interactive, the scheduler treats it properly once it has received the priority boost.

==== an example

A long-running job when competing for the CPU with two short-running interactive jobs.
#image("images/2023-12-19-12-52-55.png", width: 80%)

- On the left, there is no priority boost, and thus the long-running job gets starved once the two short jobs arrive
- On the right, there is a priority boost every 50 ms, and thus we at least guarantee that the long-running job will get boosted to the highest priority every 50 ms and thus get to run periodically.

- What should S be set to?
  - S is one of the *voo-doo constants*, because it seemed to require some form of black magic to set them correctly.

- too high, long-running jobs could starve;
- too low, and interactive jobs may not get a proper share of the CPU.

==== AVOID VOO-DOO CONSTANTS (OUSTERHOUT'S LAW)

Avoiding voo-doo constants is a good idea whenever possible.

The frequent result: a configuration file filled with default parameter values that a seasoned administrator can tweak when something isn't quite working correctly. These are often left unmodified, and thus we are left to hope that the defaults work well in the field.

=== Attempt #3: Better Accounting

How to prevent gaming of our scheduler?

The solution here is to perform better accounting of CPU time at each level of the MLFQ.

Instead of forgetting how much of a time slice a process used at a given level, the scheduler should keep track; once a process has used its allotment, it is demoted to the next priority queue. Whether it uses the time slice in one long burst or many small ones does not matter.  

We thus rewrite Rules 4a and 4b to the following single rule:

- Rule 4: Once a job uses up its time allotment at a given level (regardless of how many times it has given up the CPU), its priority is reduced (i.e., it moves down one queue).
  #tip("Tip")[
   Does this one have a side effect on interaction since it will reduced the priority?   
  ] 

#image("images/2023-12-19-16-07-00.png", width: 80%)

- Without any protection from gaming, a process can issue an I/O just before a time slice ends and thus dominate CPU time.
- With such protections in place, regardless of the I/O behavior of the process, it slowly moves down the queues, and thus cannot gain an unfair share of the CPU.

=== Tuning MLFQ And Other Issues

How to parameterize such a scheduler?

- how many queues should there be?
- How big should the time slice be per queue?
- How often should priority be boosted in order to avoid starvation and account for changes in behavior?
- ...

There are no easy answers to these questions, and thus only some experience with workloads and subsequent tuning of the scheduler will lead to a satisfactory balance.

Most MLFQ variants allow for varying time-slice length across different queues.

- The high-priority queues are usually given short time slices; they are comprised of interactive jobs, after all, and thus quickly alternating between them makes sense.
- The low-priority queues, in contrast, contain long-running jobs that are CPU-bound; hence, longer time slices work well.

#image("images/2023-12-19-16-22-00.png", width: 70%)
Two jobs run for 20 ms at the highest queue (with a 10-ms time slice), 40 ms in the middle (20-ms time slice), and with a 40-ms time slice at the lowest.

==== Solaris MLFQ implementation

The Time-Sharing scheduling class, or TS — is particularly easy to configure;

It provides a set of tables that determine exactly how the priority of a process is altered throughout its lifetime, how long each time slice is, and how often to boost the priority of a job;

An administrator can muck with this table in order to make the scheduler behave in different ways.

Default values for the table are 60 queues, with slowly increasing time-slice lengths from 20 milliseconds (highest priority) to a few hundred milliseconds (lowest), and priorities boosted around every 1 second or so.

==== Other MLFQ schedulers

They adjust priorities using mathematical formulae.  

For example, the FreeBSD scheduler (version 4.3) uses a formula to calculate the current priority level of a job, basing it on how much CPU the process has used; in addition, usage is *decayed* over time, providing the desired priority boost in a different manner than described herein.

Many schedulers have a few other features that you might encounter.

For example, some schedulers reserve the highest priority levels for operating system work; thus typical user jobs can never obtain the highest levels of priority in the system.

Some systems also allow some user *advice* to help set priorities; for example, by using the command-line utility `nice` you can increase or decrease the priority of a job and thus increase or decrease its chances of running at any given time.

===== USE ADVICE WHERE POSSIBLE

As the operating system rarely knows what is best for each and every process of the system, it is often useful to provide interfaces to allow users or administrators to provide some *hints* to the OS.

We often call such hints *advice*, as the OS might take the advice into account in order to make a better decision.  

Such hints are useful in many parts of the OS, including the scheduler (e.g., with `nice`),memory manager (e.g., `madvise`), and file system(e.g., informed prefetching and caching).

=== MLFQ: Summary

- Rule 1: If Priority(A) > Priority(B), A runs (B doesn't).
- Rule 2: If Priority(A) = Priority(B), A & B run in round-robin fashion using the time slice (quantum length) of the given queue.
- Rule 3: When a job enters the system, it is placed at the highest priority (the topmost queue).
- Rule 4: Once a job uses up its time allotment at a given level (regardless of how many times it has given up the CPU), its priority is reduced (i.e., it moves down one queue).
- Rule 5: After some time period S, move all the jobs in the system to the topmost queue.

MLFQ is interesting for the following reason: instead of demanding a priori knowledge of the nature of a job, it observes the execution of a job and prioritizes it accordingly.

In this way, it manages to achieve the best of both worlds:

- it can deliver excellent overall performance (similar to SJF/STCF) for short-running interactive jobs
- is fair and makes progress for long-running CPU-intensive workloads.

Many systems, including BSD UNIX derivatives, Solaris, and Windows NT and subsequent Windows operating systems use a form of MLFQ as their base scheduler.

== Scheduling: Proportional Share

A different type of scheduler known as a *proportional-share* scheduler, also sometimes referred to as a *fair-share* scheduler.

A simple concept: instead of optimizing for turnaround or response time, a scheduler might instead try to *guarantee that each job obtain a certain percentage of CPU time*.

An excellent early example of proportional-share scheduling is *lottery scheduling*.

The basic idea is quite simple: every so often, hold a lottery to determine which process should get to run next; processes that should run more often should be given more chances to win the lottery.

=== Basic Concept: Tickets Represent Your Share

One very basic concept: *tickets*,which are used to represent the share of a resource that a process (or user or whatever) should receive.

Two processes, A and B, and further that A has 75 tickets while B has only 25. Thus, what we would like is for A to receive 75% of the CPU and B the remaining 25%.

Lottery scheduling achieves this probabilistically (but *not deterministically*) by holding a lottery every time slice.

Holding a lottery is straightforward: the scheduler must know how many total tickets there are (in our example, there are 100). The scheduler then picks a winning ticket, which is a number from 0 to 99.

Assuming A holds tickets 0 through 74 and B 75 through 99, the winning ticket simply determines whether A or B runs. The scheduler then loads the state of that winning process and runs it.

Here is an example output of a lottery scheduler's winning tickets:

```
63 85 70 39 76 17 29 41 36 39 10 99 68 83 63 62 43 0 49
```

Here is the resulting schedule:

```
A   A A   A A A A A A   A   A A A A A
  B     B             B   B
```

#tip("Tip")[
 meeting the desired proportion, but no guarantee.   
]

==== USE RANDOMNESS

One of the most beautiful aspects of lottery scheduling is its use of randomness.

- First, random often avoids strange corner-case behaviors that a more traditional algorithm may have trouble handling.
- Second, random also is lightweight, requiring little state to track alternatives.
- Finally, random can be quite fast.

==== USE TICKETS TO REPRESENT SHARES

One of the most powerful (and basic) mechanisms in the design of lottery (and stride) scheduling is that of the *ticket*.

Waldspurger shows how tickets can be used to represent a guest operating system's share of memory [W02].

If you are ever in need of a mechanism to represent a proportion of ownership, this concept just might be the ticket.

=== Ticket Mechanisms

Lottery scheduling also provides a number of mechanisms to manipulate tickets in different and sometimes useful ways.

One way is with the concept of *ticket currency*.

Currency allows a user with a set of tickets to allocate tickets among their own jobs in whatever currency they would like; the system then automatically converts said currency into the correct global value.

Assume users A and B have each been given 100 tickets.

- User A is running two jobs, A1 and A2, and gives them each 500 tickets (out of 1000 total) in A's currency.
- User B is running only 1 job and gives it 10 tickets (out of 10 total).

```
User A -> 500 (A's currency) to A1 -> 50 (global currency)
       -> 500 (A's currency) to A2 -> 50 (global currency)
User B -> 10  (B's currency) to B1 -> 100 (global currency)
```

Another useful mechanism is *ticket transfer*.

With transfers, a process can temporarily hand off its tickets to another process.

This ability is especially useful in a client/server setting, where a client process sends a message to a server asking it to do some work on the client's behalf.

- To speed up the work, the client can pass the tickets to the server and thus try to maximize the performance of the server while the server is handling the client's request.
- When finished, the server then transfers the tickets back to the client and all is as before.

Finally, *ticket inflation* can sometimes be a useful technique.

With inflation, a process can temporarily raise or lower the number of tickets it owns.

In a competitive scenario with processes that do not trust one another, this makes little sense; one greedy process could give itself a vast number of tickets and take over the machine.

Rather, inflation can be applied in an environment where a group of processes trust one another; in such a case, if any one process knows it needs more CPU time, it can boost its ticket value as a way to reflect that need to the system, all without communicating with any other processes.

=== Implementation

All you need is a good random number generator to pick the winning ticket, a data structure to track the processes of the system (e.g., a list), and the total number of tickets.

```c
// counter: used to track if we've found the winner yet
int counter = 0;

// winner: use some call to a random number generator to
// get a value, between 0 and the total = of tickets
int winner = getrandom(0, totaltickets);

// current: use this to walk through the list of jobs
node_t *current = head;
while (current) {
  counter = counter + current->tickets;
  if (counter > winner)
  break; // found the winner
  current = current->next;
}
// 'current' is the winner: schedule it...
```

An example comprised of three processes, A, B, and C, each with some number of tickets.
#image("images/2023-12-19-20-10-35.png", width: 80%)
To make a scheduling decision, we first have to pick a random number (the winner) from the total number of tickets (400)2 Let’s say we pick the number 300.

- First, counter is incremented to 100 to account for A’s tickets; because 100 is less than 300, the loop continues.
- Then counter would be updated to 150 (B’s tickets), still less than 300 and thus again we continue.
- Finally, counter is updated to 400 (clearly greater than 300), and thus we break out of the loop with current pointing at C (the winner).

It might generally be best to organize the list *in sorted order, from the highest number of tickets to the lowest*. The ordering does not affect the correctness of the algorithm; however, it does ensure in general that the fewest number of list iterations are taken.

=== An Example

A brief study of the completion time of two jobs competing against one another, each with the same number of tickets (100) and same run time (R, which we will vary).

We’d like for each job to finish at roughly the same time, but due to the randomness of lottery scheduling, sometimes one job finishes before the other.

To quantify this difference, we define a simple *unfairness metric, U* which is simply the time the first job completes divided by the time that the second job completes.

For example, if R = 10, and the first job finishes at time 10 (and the second job at 20), U = 10/20 = 0.5.

When both jobs finish at nearly the same time, U will be quite close to 1. In this scenario, that is our goal: a perfectly fair scheduler would achieve U = 1.
#image("images/2023-12-19-20-15-48.png", width: 60%)
Plots the average unfairness as the length of the two jobs (R) is varied from 1 to 1000 over thirty trials.

As you can see from the graph, when the job length is not very long, average unfairness can be quite severe. Only as the jobs run for a significant number of time slices does the lottery scheduler approach the desired outcome.

=== How To Assign Tickets?

One approach is to assume that the users know best; in such a case, each user is handed some number of tickets, and a user can allocate tickets to any jobs they run as desired.

However, this solution is a non-solution: it really doesn’t tell you what to do. Thus, given a set of jobs, the “ticket-assignment problem” remains open.

=== Why Not Deterministic?

While randomness gets us a simple (and approximately correct) scheduler, it occasionally will not deliver the exact right proportions, especially over short time scales.

For this reason, Waldspurger invented *stride scheduling*, a deterministic fair-share scheduler . *Stride scheduling* is also straightforward. Each job in the system has a stride, which is inverse in proportion to the number of tickets it has.

In our example above, with jobs A, B, and C, with 100, 50, and 250 tickets, respectively, we can compute the stride of each by dividing some large number by the number of tickets each process has been assigned.

For example, if we divide 10,000 by each of those ticket values, we obtain the following stride values for A, B, and C: 100, 200, and 40. We call this *value the stride of each process*; every time a process runs, we will increment a counter for it (called its *pass value*) by its stride to track its global progress.The scheduler then uses the stride and pass to determine which process should run next.

The basic idea is simple: at any given time, pick the process to run that has the lowest pass value so far; when you run a process, increment its pass counter by its stride.

```c
curr = remove_min(queue); // pick client with min pass
schedule(curr); // run for quantum
curr->pass += curr->stride; // update pass using stride
insert(queue, curr); // return curr to queue
```

In our example, we start with three processes (A, B, and C), with stride values of 100, 200, and 40, and all with pass values initially at 0. Thus, at first, any of the processes might run, as their pass values are equally low. Assume we pick A (arbitrarily; any of the processes with equal low pass values can be chosen).
#image("images/2023-12-19-20-27-05.png", width: 70%)

Lottery scheduling achieves the proportions probabilistically over time; stride scheduling gets them exactly right at the end of each scheduling cycle.

Given the precision of stride scheduling, why use lottery scheduling at all? Well, lottery scheduling has one nice property that stride scheduling does not: no global state. Imagine a new job enters in the middle of our stride scheduling example above; what should its pass value be? Should it be set to 0? If so, it will monopolize the CPU. With lottery scheduling, there is no global state per process; we simply add a new process with whatever tickets it has, update the single global variable to track how many total tickets we have, and go from there. In this way, lottery makes it much easier to incorporate new processes in a sensible manner.

=== The Linux Completely Fair Scheduler (CFS)

Despite these earlier works in fair-share scheduling, the current Linux approach achieves similar goals in an alternate manner.

The scheduler, entitled the *Completely Fair Scheduler (or CFS)*, implements fair-share scheduling, but does so in a highly efficient and scalable manner.

#tip("Tip")[
    Recent studies have shown that scheduler efficiency is surprisingly important; specifically, in a study of Google datacenters, Kanev et al. show that even after aggressive optimization, scheduling uses about 5% of overall datacenter CPU time.
]

==== Basic Operation

Its goal is simple: to fairly divide a CPU evenly among all competing processes. It does so through a simple counting-based technique known as *virtual runtime (vruntime)*.

As each process runs, it accumulates `vruntime`.

In the most basic case, each process’s `vruntime` increases at the same rate, in proportion with physical (real) time.

When a scheduling decision occurs, CFS will pick the process with the lowest `vruntime` to run next.

This raises a question: how does the scheduler know when to stop the currently running process, and run the next one?
The tension here is clear:

- if CFS switches too often, fairness is increased, as CFS will ensure that each process receives its share of CPU even over miniscule time windows, but at the cost of performance (too much context switching);
- if CFS switches less often, performance is increased (reduced context switching), but at the cost of near-term fairness.

CFS manages this tension through various control parameters.

The first is `sched_latency`. CFS uses this value to determine *how long one process should run before considering a switch* (effectively determining its time slice but in a dynamic fashion).

A typical `sched_latency` value is 48 (milliseconds); CFS divides this value by the number (n) of processes running on the CPU to determine the time slice for a process, and thus ensures that over this period of time, CFS will be completely fair.

For example, if there are n = 4 processes running, CFS divides the value of `sched_latency` by n to arrive at a per-process time slice of 12 ms.

CFS then schedules the first job and runs it until it has used 12 ms of (virtual) runtime, and then checks to see if there is a job with lower `vruntime` to run instead.

In this case, there is, and CFS would switch to one of the three other jobs, and so forth.

An example where the four jobs (A, B, C, D) each run for two time slices in this fashion; two of them(C, D) then complete, leaving just two remaining, which then each run for 24 ms in round-robin fashion.

#image("images/2023-12-19-21-21-36.png")

But what if there are “too many” processes running? Wouldn’t that lead to too small of a time slice, and thus too many context switches?

Good question! And the answer is yes.

To address this issue, CFS adds another parameter, `min_granularity`, which is usually set to a value like 6 ms. CFS will never set the time slice of a process to less than this value, ensuring that not too much time is spent in scheduling overhead.

For example, if there are 10 processes running, our original calculation would divide `sched_latency` by 10 to determine the time slice (result: 4.8 ms).

However, because of `min_granularity`, CFS will set the time slice of each process to 6ms instead. Although CFS won’t (quite) be perfectly fair over the target scheduling latency (`sched_latency`) of 48 ms, it will be close, while still achieving high CPU efficiency.

Note that CFS utilizes a periodic timer interrupt, which means it can only make decisions at fixed time intervals. This interrupt goes off frequently, giving CFS a chance to wake up and determine if the current job has reached the end of its run.

If a job has a time slice that is not a perfect multiple of the timer interrupt interval, that is OK; CFS tracks `vruntime` precisely, which means that over the long haul, it will eventually approximate ideal sharing of the CPU.

==== Weighting (Niceness)

CFS also enables controls over process priority, enabling users or administrators to give some processes a higher share of the CPU.

It does this not with tickets, but through a classic UNIX mechanism known as the *nice level of a process*.

The nice parameter can be set anywhere from -20 to +19 for a process, with a default of 0.

Positive nice values imply lower priority and negative values imply higher priority; when you’re too nice, you just don’t get as much (scheduling) attention.

CFS maps the nice value of each process to a weight, as shown here:

```c
static const int prio_to_weight[40] = {
  /* -20 */ 88761, 71755, 56483, 46273, 36291,
  /* -15 */ 29154, 23254, 18705, 14949, 11916,
  /* -10 */ 9548, 7620, 6100, 4904, 3906,
  /* -5 */ 3121, 2501, 1991, 1586, 1277,
  /* 0 */ 1024, 820, 655, 526, 423,
  /* 5 */ 335, 272, 215, 172, 137,
  /* 10 */ 110, 87, 70, 56, 45,
  /* 15 */ 36, 29, 23, 18, 15,
};
```

These weights allow us to compute the effective time slice of each process (as we did before), but now accounting for their priority differences. The formula used to do so is as follows:

$"time_slice"_k = "weight"_(k)}{sum_(i=0)^(n-1)("weight"_(i))}\cdot "sched_latency"$

Assume there are two jobs, A and B.

A, because its our most precious job, is given a higher priority by assigning it a nice value of -5; $"weight"_(A)$ (from the table) is 3121.

B, because we hate it, just has the default priority (nice value equal to 0); $"weight"_(B)$ is 1026.

If you then compute the time slice of each job, you’ll find that A’s time slice is about 3/4 of sched latency (hence, 36 ms), and B’s about 1/4 (hence, 12 ms).

In addition to generalizing the time slice calculation, the way CFS calculates `vruntime` must also be adapted. Here is the new formula, which takes the actual run time that process i has accrued (runtimei) and scales it inversely by the weight of the process. In our running example, A’s `vruntime` will accumulate at one-third the rate of B’s.

$"vruntime"_(i) = "vruntime_"(i) + ("weight"_{0})/("weight_"(i)) \cdot "runtime"_(i)$

One smart aspect of the construction of the table of weights above is that the table preserves CPU proportionality ratios when the difference in nice values is constant.

For example, if process A instead had a nice value of 5 (not -5), and process B had a nice value of 10 (not 0), CFS would schedule them in exactly the same manner as before. Run through the math yourself to see why.

==== Using Red-Black Trees

For a scheduler, there are many facets of efficiency, but one of them is as simple as this: when the scheduler has to find the next job to run, it should do so as quickly as possible.

CFS addresses this by keeping processes in *a red-black tree*.

A red-black tree is one of many types of balanced trees, balanced trees do a little extra work to maintain low depths, and thus ensure that operations are logarithmic in time.

CFS does not keep all process in this structure; rather, only running (or runnable) processes are kept therein. If a process goes to sleep (waiting on an I/O to complete, or for a network packet to arrive...), it is removed from the tree and kept track of elsewhere.

Most operations (such as insertion and deletion) are logarithmic in time, i.e., O(log n).

==== Dealing With I/O And Sleeping Processes

One problem with picking the lowest vruntime to run next arises with jobs that have gone to sleep for a long period of time.

Imagine two processes, A and B, one of which (A) runs continuously, and the other (B) which has gone to sleep for a long period of time.

When B wakes up, its vruntime will be 10 seconds behind A’s, and thus, B will now monopolize the CPU for the next 10 seconds while it catches up, effectively starving A.

CFS handles this case by altering the vruntime of a job when it wakes up. Specifically, CFS sets the vruntime of that job to the minimum value found in the tree. In this way, CFS avoids starvation, but not without a cost: jobs that sleep for *short periods of time* frequently do not ever get their fair share of the CPU.

=== Summary

- Lottery uses randomness in a clever way to achieve proportional share;
- Stride does so deterministically.
- CFS is a bit like weighted round-robin with dynamic time slices, but built to scale and perform well under load
  #tip("Tip")[
   To our knowledge, it is the most widely used fair-share scheduler in existence today.   
  ] 

fair-share schedulers have their fair share of problems

- Such approaches do not particularly mesh well with I/O
- They leave open the hard problem of ticket or priority assignment
