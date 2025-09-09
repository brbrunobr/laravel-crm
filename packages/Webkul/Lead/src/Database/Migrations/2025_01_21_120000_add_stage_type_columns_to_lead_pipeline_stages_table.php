<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        Schema::table('lead_pipeline_stages', function (Blueprint $table) {
            $table->boolean('is_won_stage')->default(false)->after('probability')->comment('Mark this stage as a won/success stage for dashboard reporting');
            $table->boolean('is_lost_stage')->default(false)->after('is_won_stage')->comment('Mark this stage as a lost/failed stage for dashboard reporting');
        });
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        Schema::table('lead_pipeline_stages', function (Blueprint $table) {
            $table->dropColumn(['is_won_stage', 'is_lost_stage']);
        });
    }
};