<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\CustomUserController;
Route::get('/', function () {
    return view('welcome');
});

