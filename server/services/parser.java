import java.io.BufferedWriter;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.File;
import java.io.FileWriter;
import java.io.FileReader;

//Um pouco martelado mas pareceu funcionar bem, pode ainda ter algum bug no write, not sure, cuidado com as diretorias do ficheiro a dar parse

public class parser{
    public static void main(String args[]) {
        try{
        BufferedReader reader = new BufferedReader(new FileReader("./smallerfile_21.csv")); //meter aqui o ficheiro a transformar
        File file = new File("./newFile");
        file.createNewFile();
        FileWriter fw = new FileWriter(file);
	    BufferedWriter bw = new BufferedWriter(fw);

        String line;
        String[] line_splitted;

        //Probably mudar para double, n sei quantas entradas sao
        int counter = 0;
        while((line = reader.readLine()) != null){
            line_splitted = line.split(",");

            //NOTE: Nao sei que tipo de dados meter no event_time
            // - Confirmar também os outros event types, testei com um ficheiro de 140MB e pareceu tar ok, mas n vi com muito detalhe
            bw.write("{\"event_id\":{\"n\":\"" + (counter++) + "\"},\"event_time\":{\"?????\":\"" + line_splitted[0] + "\"},\"event_type\":{\"s\":\"" + 
                line_splitted[1] + "\"},\"product_id\":{\"n\":\"" + line_splitted[2] + "\"},\"category_id\":{\"n\":\"" + line_splitted[3] + "\"},\"category_code\":{\"s\":\"" + 
                line_splitted[4] + "\"},\"brand\":{\"s\":\"" + line_splitted[5] + "\"},\"price\":{\"n\":\"" + line_splitted[6] + "\"},\"user_id\":{\"n\":\"" +
                line_splitted[7] + "\"},\"user_session\":{\"s\":\"" + line_splitted[8] + "\"}}\n");
            bw.flush();

        }

        fw.close();
        bw.close();
        reader.close();
        }catch(Exception e){
            System.out.print("lol");
        }
    }
}