package org.swizframework.reflection
{
	public class MetadataHostProperty extends BaseMetadataHost
	{
		// ========================================
		// public properties
		// ========================================
		
		public function get isBindable():Boolean
		{
			for each( var tag:IMetadataTag in metadataTags )
			{
				if( tag.name == "Bindable" )
					return true;
			}
			
			return false;
		}
		
		// ========================================
		// constructor
		// ========================================
		
		public function MetadataHostProperty()
		{
			super();
		}
	}
}