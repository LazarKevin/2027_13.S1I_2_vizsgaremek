<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class BelepesController extends Controller
{
    public function belepes(Request $request)
    {
        // 1. Kiolvassuk a kódot, amit a Vue küldött
        $kod = $request->input('kod');

        // 2. Megkeressük a foglalást, amelyiknek ez a belépőkódja
        //    (ugyanaz, mint SQL-ben: SELECT * FROM foglalasok WHERE belepokod = '...')
        $foglalas = DB::table('foglalasok')->where('belepokod', $kod)->first();

        // 3. Ha nincs ilyen kód az adatbázisban
        if ($foglalas == null) {
            return response()->json([
                'uzenet' => 'Nincs ilyen kód.'
            ], 404);
        }

        // 4. Ha a kódot már felhasználták
        if ($foglalas->kod_felhasznalva != null) {
            return response()->json([
                'uzenet' => 'Ezt a kódot már felhasználták.'
            ], 422);
        }

        // 5. Ha a kód lejárt
        //    A mostani időt ugyanolyan formában kérjük le, mint ahogy az adatbázisban van
        $most = date('Y-m-d H:i:s');

        if ($foglalas->kod_lejarat < $most) {
            return response()->json([
                'uzenet' => 'Ez a kód már lejárt.'
            ], 422);
        }

        // 6. Minden rendben, a vendég beléphet
        //    KÉSŐBB ide jön: a kód megjelölése felhasználtként,
        //    és a vendégmenet (vendeg_menetek) létrehozása
        return response()->json([
            'uzenet' => 'Sikeres belépés!',
            'asztal_id' => $foglalas->asztal_id
        ], 200);
    }
}
