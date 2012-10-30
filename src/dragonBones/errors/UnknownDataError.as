package dragonBones.errors
{
	public final class UnknownDataError extends Error
	{
		public function UnknownDataError(message:*="", id:*=0)
		{
			super(message, id);
		}
	}
}