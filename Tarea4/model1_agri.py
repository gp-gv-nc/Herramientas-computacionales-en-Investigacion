"""
Model exported as python.
Name : model1
Group : 
With QGIS : 32208
"""
################################################################
#Se llaman los scripts a utilizar
################################################################

from qgis.core import QgsProcessing
from qgis.core import QgsProcessingAlgorithm
from qgis.core import QgsProcessingMultiStepFeedback
from qgis.core import QgsProcessingParameterRasterDestination
from qgis.core import QgsProcessingParameterFeatureSink
from qgis.core import QgsCoordinateReferenceSystem
import processing

######################################################
# se genera el archivo de model1
#####################################################

class Model1(QgsProcessingAlgorithm):

    def initAlgorithm(self, config=None):
        self.addParameter(QgsProcessingParameterRasterDestination('Agrisuit', 'agrisuit', createByDefault=True, defaultValue=None))
        self.addParameter(QgsProcessingParameterFeatureSink('Counties', 'counties', type=QgsProcessing.TypeVectorAnyGeometry, createByDefault=True, supportsAppend=True, defaultValue=None))
        self.addParameter(QgsProcessingParameterFeatureSink('Zonal', 'Zonal', type=QgsProcessing.TypeVectorAnyGeometry, createByDefault=True, supportsAppend=True, defaultValue=None))

    def processAlgorithm(self, parameters, context, model_feedback):
        # Use a multi-step feedback, so that individual child algorithm progress reports are adjusted for the
        # overall progress through the model
        feedback = QgsProcessingMultiStepFeedback(4, model_feedback)
        results = {}
        outputs = {}
        
#######################################################################
# Combar (reproyectar)
#######################################################################
#se reproyecta el mapa, creará nuevos archivos en el directorio temporal en Windows
#######################################################################

        alg_params = {
            'DATA_TYPE': 0,  # Usar el tipo de datos de la capa de entrada
            'EXTRA': '',
            'INPUT': 'C:/Users/Luis Cerda/Documents/UdeSA/Cursos/IIT/HCI/Clase4/SUIT/suit/hdr.adf',
            'MULTITHREADING': False,
            'NODATA': None,
            'OPTIONS': '',
            'RESAMPLING': 0,  # Vecino más próximo
            'SOURCE_CRS': None,
            'TARGET_CRS': QgsCoordinateReferenceSystem('EPSG:4326'),
            'TARGET_EXTENT': None,
            'TARGET_EXTENT_CRS': None,
            'TARGET_RESOLUTION': None,
            'OUTPUT': parameters['Agrisuit']
        }
        outputs['CombarReproyectar'] = processing.run('gdal:warpreproject', alg_params, context=context, feedback=feedback, is_child_algorithm=True)
        results['Agrisuit'] = outputs['CombarReproyectar']['OUTPUT']

        feedback.setCurrentStep(1)
        if feedback.isCanceled():
            return {}
##############################################################
# Quitar campo(s)
###############################################################
# Se eliminan las variables que no se van a utilizar, si se nos olvida quitar una variable, aqui podemos escribirla para elimnarla
###############################################################
        alg_params = {
            'COLUMN': ['GID_0','NAME_0','GID_1','GID_2','HASC_2','CC_2','TYPE_2','NL_NAME 2','VARNAME_2','NL_NAME_1','NL_NAME_2',' ENGTYPE_2'],
            'INPUT': 'C:/Users/Luis Cerda/Documents/UdeSA/Cursos/IIT/HCI/Clase4/input/gadm41_USA_shp/gadm41_USA_2.shp',
            'OUTPUT': QgsProcessing.TEMPORARY_OUTPUT
        }
        outputs['QuitarCampos'] = processing.run('native:deletecolumn', alg_params, context=context, feedback=feedback, is_child_algorithm=True)

        feedback.setCurrentStep(2)
        if feedback.isCanceled():
            return {}
####################################################################
# Agregar campo que auto-incrementa 
####################################################################
#Esto creará valores incrementados para las características existentes pero no para las nuevas
####################################################################
        alg_params = {
            'FIELD_NAME': 'cid',
            'GROUP_FIELDS': [''],
            'INPUT': outputs['QuitarCampos']['OUTPUT'],
            'MODULUS': 0,
            'SORT_ASCENDING': True,
            'SORT_EXPRESSION': '',
            'SORT_NULLS_FIRST': False,
            'START': 1,
            'OUTPUT': parameters['Counties']
        }
        outputs['AgregarCampoQueAutoincrementa'] = processing.run('native:addautoincrementalfield', alg_params, context=context, feedback=feedback, is_child_algorithm=True)
        results['Counties'] = outputs['AgregarCampoQueAutoincrementa']['OUTPUT']

        feedback.setCurrentStep(3)
        if feedback.isCanceled():
            return {}
############################################################
# Estadísticas de zona
############################################################
# Esto nos permite calcular estadísticas sobre píxeles de una banda ráster que se encuentran dentro de polígonos/zonas en una capa vectorial
############################################################
        alg_params = {
            'COLUMN_PREFIX': '_',
            'INPUT': outputs['AgregarCampoQueAutoincrementa']['OUTPUT'],
            'INPUT_RASTER': outputs['CombarReproyectar']['OUTPUT'],
            'RASTER_BAND': 1,
            'STATISTICS': [2],  # Media
            'OUTPUT': parameters['Zonal']
        }
        outputs['EstadsticasDeZona'] = processing.run('native:zonalstatisticsfb', alg_params, context=context, feedback=feedback, is_child_algorithm=True)
        results['Zonal'] = outputs['EstadsticasDeZona']['OUTPUT']
        return results
     
    def name(self):
        return 'model1'

    def displayName(self):
        return 'model1'

    def group(self):
        return ''

    def groupId(self):
        return ''

    def createInstance(self):
        return Model1()
    
    ##################################################################
    # Final del programa model1_Agri
    ##################################################################
