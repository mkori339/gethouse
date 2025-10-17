<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Report extends Model
{
    use HasFactory;

    protected $fillable = [
        'reporter_id',
        'report_type', // 'post' | 'agent'
        'reported_id',
        'reason',
        'details',
        'status',
    ];

    public function reporter()
    {
        return $this->belongsTo(CustomUser::class, 'reporter_id');
    }

    // helper to get the reported entity (not a strict relation because we used report_type)
    public function reported()
    {
        if ($this->report_type === 'post') {
            return Post::find($this->reported_id);
        } elseif ($this->report_type === 'agent') {
            return Agent::find($this->reported_id);
        }
        return null;
    }
}
