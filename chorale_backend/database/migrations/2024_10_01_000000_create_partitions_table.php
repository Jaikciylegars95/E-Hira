<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('partitions', function (Blueprint $table) {
            $table->id();
            $table->string('titre');
            $table->string('categorie');
            $table->string('pdf_url');
            $table->string('audio_url');
            $table->integer('version')->default(1);
            $table->boolean('is_favorite')->default(false);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('partitions');
    }
};
