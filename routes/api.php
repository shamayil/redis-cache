<?php


use App\Jobs\ProcessHighPriorityJob;
use App\Jobs\ProcessLowPriorityJob;
use App\Jobs\ProcessMediumPriorityJob;
use Illuminate\Support\Facades\Route;

Route::post('/trigger-low-priority', function () {
    ProcessLowPriorityJob::dispatch()->onConnection('low');
});

Route::post('/trigger-medium-priority', function () {
    ProcessMediumPriorityJob::dispatch()->onConnection('medium');
});

Route::post('/trigger-high-priority', function () {
    ProcessHighPriorityJob::dispatch()->onConnection('high');
});
