<?php

namespace App\Providers;

use Illuminate\Support\Facades\Log;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Log the SQS connection details
        $sqsPrefix = config('queue.connections.medium.prefix');
        $sqsQueue = config('queue.connections.medium.queue');
        $sqsRegion = config('queue.connections.medium.region');

        Log::info('SQS Configuration', [
            'prefix' => $sqsPrefix,
            'queue' => $sqsQueue,
            'region' => $sqsRegion,
            'full_url' => $sqsPrefix . '/' . $sqsQueue
        ]);
    }
}
