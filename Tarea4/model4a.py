"""
Model exported as python.
Name : model4a
Group : 
With QGIS : 32208
"""

from qgis.core import QgsProcessing
from qgis.core import QgsProcessingAlgorithm
from qgis.core import QgsProcessingMultiStepFeedback
from qgis.core import QgsProcessingParameterFeatureSink
import processing


class Model4a(QgsProcessingAlgorithm):

    def initAlgorithm(self, config=None):
        self.addParameter(QgsProcessingParameterFeatureSink('Fixgeo_wlds', 'fixgeo_wlds', type=QgsProcessing.TypeVectorAnyGeometry, createByDefault=True, supportsAppend=True, defaultValue=None))
        self.addParameter(QgsProcessingParameterFeatureSink('Fixgeo_countries', 'fixgeo_countries', type=QgsProcessing.TypeVectorAnyGeometry, createByDefault=True, supportsAppend=True, defaultValue=None))
        self.addParameter(QgsProcessingParameterFeatureSink('Intersection', 'intersection', type=QgsProcessing.TypeVectorAnyGeometry, createByDefault=True, defaultValue=None))

    def processAlgorithm(self, parameters, context, model_feedback):
        # Use a multi-step feedback, so that individual child algorithm progress reports are adjusted for the
        # overall progress through the model
        feedback = QgsProcessingMultiStepFeedback(4, model_feedback)
        results = {}
        outputs = {}

        # Fix geometries - wlds
        alg_params = {
            'INPUT': '/Users/gonzalorigirozzi/Desktop/Clase 4/OUTPUT/clean.shp',
            'OUTPUT': parameters['Fixgeo_wlds']
        }
        outputs['FixGeometriesWlds'] = processing.run('native:fixgeometries', alg_params, context=context, feedback=feedback, is_child_algorithm=True)
        results['Fixgeo_wlds'] = outputs['FixGeometriesWlds']['OUTPUT']

        feedback.setCurrentStep(1)
        if feedback.isCanceled():
            return {}

        # Fix geometries - contries
        alg_params = {
            'INPUT': '/Users/gonzalorigirozzi/Downloads/ne_10m_admin_0_countries/ne_10m_admin_0_countries.shp',
            'OUTPUT': parameters['Fixgeo_countries']
        }
        outputs['FixGeometriesContries'] = processing.run('native:fixgeometries', alg_params, context=context, feedback=feedback, is_child_algorithm=True)
        results['Fixgeo_countries'] = outputs['FixGeometriesContries']['OUTPUT']

        feedback.setCurrentStep(2)
        if feedback.isCanceled():
            return {}

        # Statistics by categories
        alg_params = {
            'CATEGORIES_FIELD_NAME': ['ADMIN'],
            'INPUT': 'Intersection_7a8169c8_148a_4cd5_892a_d79533348735',
            'OUTPUT': '/Users/gonzalorigirozzi/Desktop/Clase 4/OUTPUT/languages_by_country.csv',
            'VALUES_FIELD_NAME': '',
            'OUTPUT': QgsProcessing.TEMPORARY_OUTPUT
        }
        outputs['StatisticsByCategories'] = processing.run('qgis:statisticsbycategories', alg_params, context=context, feedback=feedback, is_child_algorithm=True)

        feedback.setCurrentStep(3)
        if feedback.isCanceled():
            return {}

        # Intersection
        alg_params = {
            'INPUT': outputs['FixGeometriesWlds']['OUTPUT'],
            'INPUT_FIELDS': ['GID'],
            'OVERLAY': outputs['FixGeometriesContries']['OUTPUT'],
            'OVERLAY_FIELDS': ['ADMIN'],
            'OVERLAY_FIELDS_PREFIX': '',
            'OUTPUT': parameters['Intersection']
        }
        outputs['Intersection'] = processing.run('native:intersection', alg_params, context=context, feedback=feedback, is_child_algorithm=True)
        results['Intersection'] = outputs['Intersection']['OUTPUT']
        return results

    def name(self):
        return 'model4a'

    def displayName(self):
        return 'model4a'

    def group(self):
        return ''

    def groupId(self):
        return ''

    def createInstance(self):
        return Model4a()
