<?php

namespace App\Console\Commands;

use Illuminate\Console\Command;

class TestCommand extends Command
{

    protected $signature = 'log:test';

    public function __construct()
    {
        parent::__construct();
    }

    public function handle()
    {
        Logger('stderr error message');
    }
}
