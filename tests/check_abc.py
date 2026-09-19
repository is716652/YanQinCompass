import zipfile
import io

app = r'build\outputs\release\YanQinCompass-release-signed.app'
inner = zipfile.ZipFile(app).read('entry-default.hap')
abc = zipfile.ZipFile(io.BytesIO(inner)).read('ets/modules.abc')
for kw in ['DailyTheater', 'theaterText', 'bestiaryMap', 'updateDaily', 'refreshPreview', 'loadDailySupport']:
    print(kw, 'in abc:', kw.encode('utf-8') in abc)
