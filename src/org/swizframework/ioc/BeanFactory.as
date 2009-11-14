package org.swizframework.ioc
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	import flash.utils.describeType;
	import flash.utils.getQualifiedClassName;
	
	import org.swizframework.ISwiz;
	import org.swizframework.di.Bean;
	import org.swizframework.events.BeanEvent;
	import org.swizframework.processors.IBeanProcessor;
	import org.swizframework.processors.IMetadataProcessor;
	import org.swizframework.processors.IProcessor;
	import org.swizframework.reflection.IMetadataTag;
	import org.swizframework.reflection.TypeCache;
	import org.swizframework.reflection.TypeDescriptor;
	
	/**
	 * Bean Factory
	 */
	public class BeanFactory extends EventDispatcher implements IBeanFactory
	{
		
		// ========================================
		// private properties
		// ========================================
		
		private var _injectionEvent:String = "addedToStage";
		
		// ========================================
		// protected properties
		// ========================================
		
		protected var swiz:ISwiz;
		protected var ignoredClasses:RegExp = /^mx\./;
		
		/**
		 * 
		 */
		protected var typeDescriptors:Dictionary;
		
		// ========================================
		// public properties
		// ========================================
		
		/**
		 * @inheritDoc
		 */
		public function get injectionEvent():String
		{
			return _injectionEvent;
		}
		
		public function set injectionEvent( value:String ):void
		{
			_injectionEvent = value;
		}
		
		// ========================================
		// constructor
		// ========================================
		
		/**
		 * Constructor
		 */
		public function BeanFactory()
		{
			super();
		}
		
		// ========================================
		// public methods
		// ========================================
		
		/**
		 * @inheritDoc
		 */
		public function init( swiz:ISwiz ):void
		{
			this.swiz = swiz;
			
			for each ( var processor:IProcessor in swiz.processors )
			{
				processor.init( swiz );
			}
			
			addBeanProviders( swiz.beanProviders );
			
			swiz.dispatcher.addEventListener( injectionEvent, injectionEventHandler, true, 50, true );
		}
		
		// ========================================
		// protected methods
		// ========================================
		
		/**
		 * Get TypeDescriptor instance for provided bean. If a TypeDescriptor
		 * has already been created for this type that instance will be returned.
		 * 
		 * @see org.swizframework.di.TypeDescriptor
		 */
		protected function getTypeDescriptor( beanInstance:* ):TypeDescriptor
		{
			typeDescriptors ||= new Dictionary();
			
			// name of the property's class
			var beanClassName:String = getQualifiedClassName( beanInstance );
			
			var td:TypeDescriptor = typeDescriptors[ beanClassName ];
			
			// check to see if we already have a TypeDescriptor for this class type
			if( td == null )
			{
				// existing TypeDescriptor not found, so create one and store it
				// TODO: implement type caching
				td = new TypeDescriptor().fromXML( describeType( beanInstance ) );
				typeDescriptors[ beanClassName ] = td;
			}
			
			return td;
		}
		
		/**
		 * Add Bean Providers
		 */
		protected function addBeanProviders( beanProviders:Array ):void
		{
			for each( var beanProvider:IBeanProvider in beanProviders )
			{
				addBeanProvider( beanProvider );
			}
		}
		
		/**
		 * Add Bean Provider
		 */
		protected function addBeanProvider( beanProvider:IBeanProvider ):void
		{
			var bean:Bean;
			
			for each ( var beanSource:Object in beanProvider.beans )
			{
				if( beanSource is Bean )
				{
					bean = Bean( beanSource );
				}
				else
				{
					bean = new Bean();
					bean.source = beanSource;
				}
				
				bean.typeDescriptor = getTypeDescriptor( bean.source );
				
				addBean( bean );
			}
			
			beanProvider.addEventListener( BeanEvent.ADDED, beanAddedHandler );
		}
		
		protected function getBean( source:Object ):Bean
		{
			if( source is Bean )
				return Bean( source );
			
			var bean:Bean = new Bean();
			bean.source = source;
			bean.typeDescriptor = getTypeDescriptor( source );
			return bean;
		}
		
		/**
		 * Remove Bean Provider
		 */
		protected function removeBeanProvider( beanProvider:IBeanProvider ):void
		{
			for each ( var bean:Bean in beanProvider.beans )
			{
				removeBean( bean );
			}
			
			beanProvider.removeEventListener( BeanEvent.REMOVED, beanRemovedHandler );
		}
		
		/**
		 * Add Bean
		 */
		protected function addBean( bean:Bean ):void
		{
			for each ( var processor:IProcessor in swiz.processors )
			{
				// Handle Bean Processors
				if ( processor is IBeanProcessor )
				{
					var beanProcessor:IBeanProcessor = IBeanProcessor( processor );
					beanProcessor.addBean( bean );
				}
				
				// Handle Metadata Processors
				if ( processor is IMetadataProcessor )
				{
					var metadataProcessor:IMetadataProcessor = IMetadataProcessor( processor );
					//var metadatas:Array = MetadataUtil.findMetadataByName( bean, metadataProcessor.metadataName, metadataProcessor.metadataClass );
					var metadataTags:Array = TypeCache.getTypeDescriptor( bean.source ).getMetadataTagsByName( metadataProcessor.metadataName );
					
					for each ( var metadataTag:IMetadataTag in metadataTags )
					{
						metadataProcessor.addMetadata( bean, metadataTag );
					}
				}
			}
		}
		
		/**
		 * Remove Bean
		 */
		protected function removeBean( bean:Bean ):void
		{
			for each ( var processor:IProcessor in swiz.processors )
			{
				// Handle Metadata Processors
				if ( processor is IMetadataProcessor )
				{
					var metadataProcessor:IMetadataProcessor = IMetadataProcessor( processor );
					//var metadatas:Array = MetadataUtil.findMetadataByName( bean, metadataProcessor.metadataName, metadataProcessor.metadataClass );
					var metadataTags:Array = TypeCache.getTypeDescriptor( bean ).getMetadataTagsByName( metadataProcessor.metadataName );
					
					for each ( var metadataTag:IMetadataTag in metadataTags )
					{
						metadataProcessor.removeMetadata( bean, metadataTag );
					}
				}
				
				// Handle Bean Processors
				if ( processor is IBeanProcessor )
				{
					var beanProcessor:IBeanProcessor = IBeanProcessor( processor );
					
					beanProcessor.removeBean( bean );
				}
			}
		}
		
		/**
		 * Injection Event Handler
		 */
		protected function injectionEventHandler( event:Event ):void
		{
			var className:String = getQualifiedClassName( event.target );
			
			if ( ! ignoredClasses.test( className ) )
			{
				addBean( getBean( event.target ) );
			}
		}
		
		// ========================================
		// private methods
		// ========================================
		
		/**
		 * Bean Added Handler
		 */
		private function beanAddedHandler( event:BeanEvent ):void
		{
			addBean( getBean( event.bean ) );
		}
		
		/**
		 * Bean Added Handler
		 */
		private function beanRemovedHandler( event:BeanEvent ):void
		{
			removeBean( getBean( event.bean ) );
		}
	}
}