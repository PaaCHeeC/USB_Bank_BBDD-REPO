import os
import errno

# esta funcion verifica si el directorio de nombre dado, esta creado
# en la misma ruta donde esta el archivo generador_reportes.py
# Si el directorio existe, arroja un error especificado, en caso contrario
# crea el directorio con el nombre dado y retorna un mensaje indicando que se
# creo satisfactoriamente el directorio


def creacion_de_carpeta_reportes(directorio: str) -> str:

    try:
        os.mkdir(directorio)
        carpetas_reportes = ['reportes_estadisticos', 'reportes_contables']
        for carpeta in carpetas_reportes:
            ruta_completa = os.path.join('reportes_generados', carpeta)
            os.makedirs(ruta_completa, exist_ok=True)
        print('Creacion de las carpetas de reportes en el directorio reportes_generados')


        return 'Directorio {} creado satisfactoriamente'.format(directorio)
    except OSError as e:
        if e.errno == errno.EEXIST:
            return 'El directorio {} ya existe'.format(directorio)
        else:
            return 'error inesperado al crear el directorio {}'.format(directorio)


result = creacion_de_carpeta_reportes('reportes_generados')
print(result)
