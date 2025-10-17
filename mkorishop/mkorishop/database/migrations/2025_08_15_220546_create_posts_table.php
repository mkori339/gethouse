<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('posts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained('custom_users')->onDelete('cascade');
            $table->string('poster');
            $table->string('category');
            $table->string('type');
            $table->decimal('amount', 12, 2)->nullable();
            $table->text('explanation')->nullable();
            $table->string('region')->nullable();
            $table->string('district')->nullable();
            $table->string('street')->nullable();
            $table->string('room_no')->nullable();
            $table->string('status')->default('pending'); // pending | paid | rejected
            $table->timestamps();
        });
    }

    public function down()
    {
        Schema::dropIfExists('posts');
    }
};
