<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Partition extends Model
{
    protected $table = 'partitions'; // facultatif si table = plural du modèle
    protected $fillable = ['titre', 'categorie', 'pdf_url', 'audio_url', 'version'];

    // Pour l'API : retourne les URLs complètes
    public function toArray()
    {
        $array = parent::toArray();
        $array['pdf_url'] = url("storage/{$array['pdf_url']}");
        $array['audio_url'] = url("storage/{$array['audio_url']}");
        return $array;
    }
}
