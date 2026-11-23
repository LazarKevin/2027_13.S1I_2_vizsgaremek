<?php

use Illuminate\Support\Facades\Route;

use App\Http\Controllers\BelepesController;

Route::post('/belepes', [BelepesController::class, 'belepes']);
