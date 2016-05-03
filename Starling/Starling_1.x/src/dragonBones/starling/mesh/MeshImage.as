package dragonBones.starling.mesh 
{
	import dragonBones.starling.mesh.Mesh;
	import dragonBones.starling.mesh.MeshBatch;
	import dragonBones.objects.MeshData;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;
	import starling.core.RenderSupport;
	import starling.textures.Texture;
	import starling.textures.TextureSmoothing;
	import starling.utils.VertexData;
	/**
	 * ...
	 * @author sukui
	 */
	public class MeshImage extends Mesh
	{
		public static var meshBatch:MeshBatch;
		
		private var mTexture:Texture;
        private var mSmoothing:String;
		
		private var mVertexDataCache:VertexData;
        private var mVertexDataCacheInvalid:Boolean;
		
		public function MeshImage(texture:Texture,meshData:MeshData, color:uint=0xffffff)
		{
			if (texture)
            {
                var pma:Boolean = texture.premultipliedAlpha;
                
                mTexture = texture;
                mSmoothing = TextureSmoothing.BILINEAR;
				
				super(meshData, color, pma);
				
				mVertexDataCache = new VertexData(this.meshData.numVertex, pma);
                mVertexDataCacheInvalid = true;
            }
            else
            {
                throw new ArgumentError("Texture cannot be null");
            }
			
			if (meshBatch == null)
			{
				meshBatch = new MeshBatch();
			}
		}
		
		override public function onVertexDataChanged():void 
		{
			mVertexDataCacheInvalid = true;
		}
		/** The texture that is displayed on the quad. */
        public function get texture():Texture { return mTexture; }
        public function set texture(value:Texture):void 
        { 
            if (value == null)
            {
                throw new ArgumentError("Texture cannot be null");
            }
            else if (value != mTexture)
            {
                mTexture = value;
                mVertexData.setPremultipliedAlpha(mTexture.premultipliedAlpha);
                onVertexDataChanged();
            }
        }
        
        /** The smoothing filter that is used for the texture. 
        *   @default bilinear
        *   @see starling.textures.TextureSmoothing */ 
        public function get smoothing():String { return mSmoothing; }
        public function set smoothing(value:String):void 
        {
            if (TextureSmoothing.isValid(value))
                mSmoothing = value;
            else
                throw new ArgumentError("Invalid smoothing mode: " + value);
        }
        
        /** @inheritDoc */
        public override function render(support:RenderSupport, parentAlpha:Number):void
        {
			super.render(support, parentAlpha);
			meshBatch.render(this, support, parentAlpha);
        }
		
		/** Copies the raw vertex data to a VertexData instance.
         *  The texture coordinates are already in the format required for rendering. */ 
        public override function copyVertexDataTo(targetData:VertexData, targetVertexID:int=0):void
        {
            copyVertexDataTransformedTo(targetData, targetVertexID, null);
        }
		
		/** Transforms the vertex positions of the raw vertex data by a certain matrix
         *  and copies the result to another VertexData instance.
         *  The texture coordinates are already in the format required for rendering. */
        public override function copyVertexDataTransformedTo(targetData:VertexData,
                                                             targetVertexID:int=0,
                                                             matrix:Matrix=null):void
        {
            if (mVertexDataCacheInvalid)
            {
                mVertexDataCacheInvalid = false;
                mVertexData.copyTo(mVertexDataCache);
                mTexture.adjustVertexData(mVertexDataCache, 0, this.meshData.numVertex);
            }
            
            mVertexDataCache.copyTransformedTo(targetData, targetVertexID, matrix, 0, this.meshData.numVertex);
        }
	}

}