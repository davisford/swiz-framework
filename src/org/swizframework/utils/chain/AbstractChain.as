package org.swizframework.utils.chain
{
	import flash.events.IEventDispatcher;
	
	public class AbstractChain implements IChain, IChainMember
	{
		public const SEQUENCE:int = 0;
		public const PARALLEL:int = 1;
		
		public var mode:int = SEQUENCE;
		
		public var members:Array = [];
		
		/**
		 * Backing variable for <code>dispatcher</code> getter/setter.
		 */
		protected var _dispatcher:IEventDispatcher;
		
		/**
		 *
		 */
		public function get dispatcher():IEventDispatcher
		{
			return _dispatcher;
		}
		
		public function set dispatcher( value:IEventDispatcher ):void
		{
			_dispatcher = value;
		}
		
		/**
		 * Backing variable for <code>chain</code> getter/setter.
		 */
		protected var _chain:IChain;
		
		/**
		 *
		 */
		public function get chain():IChain
		{
			return _chain;
		}
		
		public function set chain( value:IChain ):void
		{
			_chain = value;
		}
		
		protected var _isComplete:Boolean;
		
		public function get isComplete():Boolean
		{
			return _isComplete;
		}
		
		/**
		 * Backing variable for <code>position</code> getter/setter.
		 */
		protected var _position:int = -1;
		
		/**
		 *
		 */
		public function get position():int
		{
			return _position;
		}
		
		public function set position( value:int ):void
		{
			_position = value;
		}
		
		/**
		 * Backing variable for <code>stopOnError</code> getter/setter.
		 */
		protected var _stopOnError:Boolean;
		
		/**
		 *
		 */
		public function get stopOnError():Boolean
		{
			return _stopOnError;
		}
		
		public function set stopOnError( value:Boolean ):void
		{
			_stopOnError = value;
		}
		
		public function AbstractChain( dispatcher:IEventDispatcher, stopOnError:Boolean = true )
		{
			this.dispatcher = dispatcher;
			this.stopOnError = stopOnError;
		}
		
		/**
		 *
		 */
		public function addMember( member:IChainMember ):IChain
		{
			member.chain = this;
			members.push( member );
			return this;
		}
		
		/**
		 *
		 */
		public function hasNext():Boolean
		{
			return position + 1 < members.length;
		}
		
		/**
		 *
		 */
		public function start():void
		{
			position = -1;
			proceed();
		}
		
		public function stepComplete():void
		{
			if( mode == SEQUENCE )
			{
				proceed();
			}
			else
			{
				for( var i:int = 0; i < members.length; i++ )
				{
					if( !IChainMember( members[ i ] ).isComplete )
						return;
				}
				complete();
			}
		}
		
		/**
		 *
		 */
		public function proceed():void
		{
			if( mode == SEQUENCE )
			{
				if( hasNext() )
				{
					position++;
					doProceed();
				}
				else
				{
					complete();
				}
			}
			else
			{
				for( var i:int = 0; i < members.length; i++ )
				{
					position = i;
					doProceed();
				}
			}
		}
		
		/**
		 *
		 */
		public function doProceed():void
		{
			// TODO: write error msg
			throw new Error();
		}
		
		/**
		 *
		 */
		public function stepError():void
		{
			// TODO: dispatch event
			if( !stopOnError )
				proceed();
			else
				fail();
		}
		
		/**
		 *
		 */
		protected function complete():void
		{
			// TODO: dispatch event
			_isComplete = true;
			if( chain != null )
				chain.stepComplete();
		}
		
		/**
		 *
		 */
		protected function fail():void
		{
			// TODO: dispatch event
			_isComplete = true;
			if( chain != null )
				chain.stepError();
		}
	}
}