import pandas as pd
from math import sin,cos,sqrt,atan2,radians
import json
import re

excel_file = 'dataset.xlsx'

data = pd.read_excel(excel_file, sheet_name='Folha1')

data['PONTO_RECOLHA_LOCAL'] = data['PONTO_RECOLHA_LOCAL'].str.normalize('NFKD').str.encode('ascii', errors='ignore').str.decode('utf-8')
data['CONTENTOR_RESÍDUO'] = data['CONTENTOR_RESÍDUO'].str.normalize('NFKD').str.encode('ascii', errors='ignore').str.decode('utf-8')

locais = {}

for line in data.values:
    lat = line[0]
    longi = line[1]
    tipo = line[5]
    qtd = line[9]

    if n := re.match(r'^\d+: ((\w+[ \-]?)+)',line[4]):
      nome = n.group(1)
      if nome[-1] == ' ':
        nome = nome[:-1]

    if nome in locais:
        content = locais.get(nome)
        if tipo in content['Tipo_residuo']:
            locais[nome]['Tipo_residuo'][tipo] += qtd
        else:
            locais[nome]['Tipo_residuo'][tipo] = qtd
    else:
        locais[nome] = {}
        locais[nome]['latitude'] = lat
        locais[nome]['longitude'] = longi
        locais[nome]['Tipo_residuo'] = {tipo : qtd}

# print(json.dumps(locais, sort_keys=True, indent=4))

full = open('pontos_recolha.pl','w+', encoding='utf-8')
full.write('%% ponto_recolha(Nome,Lat,Long,Tipo,QtdTotal)\n')
for local in locais:
    content = locais.get(local)
    for tipo in content['Tipo_residuo']:
        full.write(f"ponto_recolha('{local}',{content['latitude']},{content['longitude']},'{tipo}',{content['Tipo_residuo'].get(tipo)}).\n")
full.close()


def calc_distance(lat1,lon1,lat2,lon2):
  R = 6373.0

  dlon = lon2 - lon1
  dlat = lat2 - lat1

  a = sin(dlat / 2)**2 + cos(lat1) * cos(lat2) * sin(dlon / 2)**2
  c = 2 * atan2(sqrt(a), sqrt(1 - a))

  distance = R * c
  return distance*1000


result = {}
ligacoes = {
  "R do Alecrim" : ['R Ferragial', 'R Ataide', 'Pc Duque da Terceira','Tv Guilherme Cossoul'],
  "R Corpo Santo" : ['Lg Corpo Santo', 'Tv Corpo Santo'],
  "Tv Corpo Santo" : ['R Bernardino da Costa', 'Cais do Sodre'],
  "R Bernardino da Costa" : ['Lg Corpo Santo', 'Pc Duque da Terceira'],
  "Lg Conde-Barao" : ['R da Boavista', 'Bqr do Duro', 'R Mastros', 'Tv do Cais do Tojo'],
  "Tv Marques de Sampaio" : ['R da Boavista'],
  "R da Boavista" : ['R Sao Paulo', 'Bqr dos Ferreiros', 'Pto Galega', 'R Instituto Insdustrial'],
  "Tv do Cais do Tojo" : ['R Cais do Tojo'],
  "R Cais do Tojo" : ['Av Dom Carlos I', 'Bqr do Duro'],
  "Bqr do Duro" : ['R Dom Luis I'],
  "Tv Santa Catarina" : ['R da Santa Catarina','Tv da Condessa do Rio','R O Seculo'],
  "R Instituto Industrial" : ['Av 24 de Julho', 'R Dom Luis I'],
  "R Santa Catarina" : ['Tv da Condessa do Rio','R Ferreiros a Santa Catarina'],
  "R Moeda" : ['R Sao Paulo', 'Pc Dom Luis I'],
  "Tv Carvalho" : ['R Ribeira Nova', 'Pc Sao Paulo', 'R Sao Paulo'],
  "R Dom Luis I" : ['Av Dom Carlos I', 'Bqr dos Ferreiros', 'Pc Dom Luis I'],
  "Pc Dom Luis I" : ['Av 24 de Julho', 'R Ribeira Nova'],
  "R Ribeira Nova" : ['R Remolares', 'R Instituto Dona Amelia'],
  "R Sao Paulo" : ['R Corpo Santo', 'R Flores', 'Pc Sao Paulo', 'Tv dos Remolares', 'Tv Corpo Santo', 'Bc da Moeda', 'Cc da Bica Grande'],
  "R Nova do Carvalho" : ['Pc Sao Paulo', 'Tv dos Remolares', 'R do Alecrim', 'Tv Corpo Santo'],
  "R Remolares" : ['Pc Duque da Terceira', 'Tv dos Remolares', 'Tv Ribeira Nova', 'Pc Ribeira Nova'],
  "Tv dos Remolares" : ['Av 24 de Julho'],
  "Cais do Sodre" : ['Av 24 de Julho', 'R Cintura', 'Pc Duque da Terceira', 'Lg Corpo Santo'],
  "Bc da Boavista" : ['R da Boavista'],
  "Tv Ribeira Nova" : ['R Nova do Carvalho', 'Av 24 Julho', 'R Ribeira Nova'],
  "Pc Sao Paulo" : ['Tv Ribeira Nova'],
  "Lg Corpo Santo" : ['R Arsenal', 'Cc do Ferragial'],
  "Bc Francisco Andre" : ['R da Boavista'],
  "Tv de Sao Paulo" : ['Pc Sao Paulo', 'R Ribeira Nova'],
  "Av 24 de Julho" : ['Pc Duque da Terceira', 'Pc Ribeira Nova'],
  "R Marcos Portugal" : ['R Imprensa Nacional','R Quintinha'],
  "Tv Andre Valente" : ['R O Seculo'],
  "R Emenda" : ['Tv Guilherme Cossoul'],
  "R Salgadeiras" : ['R Diario de Noticias'],
  "Tv Guilherme Cossoul" : ['R Ataide'],
  "R Sao Bento" : ['R Poco dos Negros', 'R Imprensa Nacional','R Correia Garcao'],
  "R Vitor Cordon" : ['Cc do Ferragial'],
  "Cc do Ferragial" : ['R Ferragial'],
  "R Teixeira": ['R Diario de Noticias'],
  "R Poco dos Negros" : ['Av Dom Carlos I', 'R dos Mastros','R Cruz dos Poiais de Sao Bento'],
  "R Correia Garcao" : ['Av Dom Carlos I'],
  "R Cruz do Poiais de Sao Bento" : ['R Sao Bento'],
  "R da Cintura do Porto de Lisboa" : ['Av 24 de Julho'],
  "R Marechal Saldanha" : ['R Santa Catarina'],
  "R Loreto" : ['R Emenda'],
  "R Antonio Maria Cardoso" : ['R Vitor Cordon'],
  "Tv Sequeiro" : ['R Marechal Saldanha', 'R Emenda'],
  "R Quintinha" : ['R Sao Bento']
}

# print(json.dumps(ligacoes, sort_keys=True, indent=4))

arc = open('arcos.pl','w+',encoding='utf-8')
arcos = set()
arc.write('%% arco(Ponto1,Ponto2,Distancia)\n')

for c1, o1 in locais.items():
  for c2, o2 in locais.items():
    if c1 == c2: # Skip distance to itself
      continue
    if c1 not in result:
      result[c1] = {}
    if c2 not in result:
      result[c2] = {}
    if c2 in result[c1]: # Skip calculation if result exists
      continue
    lat1, long1 = o1['latitude'] , o1['longitude']
    lat2, long2 = o2['latitude'] , o2['longitude']
    lat1, long1, lat2, long2 = float(lat1), float(long1), float(lat2), float(long2)
    dist = calc_distance(radians(lat1), radians(long1), radians(lat2), radians(long2))
    result[c1][c2] = dist
    result[c2][c1] = dist

# print(json.dumps(result, sort_keys=True, indent=4))


verificados = set()

count = 0
for ponto in result:
    ligacoes_ponto1 = ligacoes.get(ponto)
    content = result.get(ponto)
    for ponto2 in content:
      if ((ponto,ponto2) not in verificados) or ((ponto2,ponto) not in verificados):
        if ligacoes_ponto1:
          if ponto2 in ligacoes_ponto1:
            arcos.add(f"arco('{ponto}','{ponto2}',{content.get(ponto2)}).\n")
            verificados.add((ponto,ponto2))
      else:
        pass



for l in arcos:
  arc.write(l)
arc.close()