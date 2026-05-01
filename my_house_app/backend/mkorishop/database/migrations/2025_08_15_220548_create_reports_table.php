<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up()
    {
        Schema::create('reports', function (Blueprint $table) {
            $table->id();
            $table->foreignId('reporter_id')->constrained('custom_users')->onDelete('cascade');
            $table->string('report_type'); // 'post' | 'agent'
            $table->unsignedBigInteger('reported_id');
            $table->text('reason')->nullable();
            $table->text('details')->nullable();
            $table->string('status')->default('open'); // open | closed
            $table->timestamps();

            // no FK on reported_id because it can point to different tables
        });
    }

    public function down()
    {
        Schema::dropIfExists('reports');
    }
};
