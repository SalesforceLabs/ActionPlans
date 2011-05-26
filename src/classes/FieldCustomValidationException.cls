/**
* Class to manage custom validation exceptions
*/
public class FieldCustomValidationException extends Exception{

	private DmlException dmlException;

	/**
	* Constructor
	*/	
	public FieldCustomValidationException( DmlException e ){
		
		this.dmlException = e;
	}
	
	public String getCustomMessage(){
		
		String message = this.dmlException.getDmlMessage( 0 );
		
		return message;
	}
	
	
	public static testmethod void testCustomMessage(){
		
		try{
			Account c = new Account();
			insert c;
		}
		catch( DmlException e1 ) {
			try{
				throw new FieldCustomValidationException( e1 );
			}
			catch( FieldCustomValidationException e2 ){
				System.assert( e2.getCustomMessage() != '' );
			}
			
		}
	}
}