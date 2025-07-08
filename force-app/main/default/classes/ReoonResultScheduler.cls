global class ReoonResultScheduler implements Schedulable {
    String taskId;

    public ReoonResultScheduler(String taskId) {
        this.taskId = taskId;
    }

    global void execute(SchedulableContext sc) {
        System.enqueueJob(new ReoonResultFetcherQueueable(taskId));
    }
}//test class